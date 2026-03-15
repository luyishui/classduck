import '../domain/import_course.dart';
import '../domain/import_table.dart';

class XjtuScheduleHtmlParser {
  static ImportTable parse(String html, {String schoolName = '西安交通大学'}) {
    final RegExp selectedTermExp = RegExp(
      r'<option\s+selected="selected"\s+value="(\d+)">([^<]+)</option>',
      caseSensitive: false,
    );
    final Match? selectedTerm = selectedTermExp.firstMatch(html);
    final String termName = selectedTerm?.group(2)?.trim() ?? '当前学期';

    final RegExp entryExp = RegExp(
      r'document\.getElementById\("td_(\d)_(\d{1,2})"\).*?'
      r'td\.innerHTML\+="课程：(.*?)<br>班级：(.*?)<br>教师：(.*?)<br>教室：(.*?)<br>节次：(.*?)<br>周次：第(.*?)周";',
      dotAll: true,
      caseSensitive: false,
    );

    final List<ImportCourse> courses = <ImportCourse>[];
    final Set<String> dedupeKeys = <String>{};

    for (final Match match in entryExp.allMatches(html)) {
      final int weekDay = int.tryParse(match.group(1) ?? '') ?? 0;
      final int rowSection = int.tryParse(match.group(2) ?? '') ?? 0;
      final String name = _cleanText(match.group(3));
      final String classNumber = _cleanText(match.group(4));
      final String teacher = _cleanText(match.group(5));
      final String classroom = _cleanText(match.group(6));
      final String sectionExpr = _cleanText(match.group(7));
      final String weekExpr = _cleanText(match.group(8));

      if (weekDay < 1 || weekDay > 7 || rowSection < 1 || name.isEmpty) {
        continue;
      }

      final List<int> weeks = _parseWeeks(weekExpr);
      if (weeks.isEmpty) {
        continue;
      }

      final int timeCount = _parseTimeCount(sectionExpr, rowSection);
      if (timeCount <= 0) {
        continue;
      }

      final String dedupeKey = '$weekDay|$rowSection|$name|$teacher|$classroom|$sectionExpr|$weekExpr';
      if (!dedupeKeys.add(dedupeKey)) {
        continue;
      }

      courses.add(
        ImportCourse(
          name: name,
          classroom: classroom,
          classNumber: classNumber,
          teacher: teacher,
          weeks: weeks,
          weekTime: weekDay,
          startTime: rowSection,
          timeCount: timeCount,
        ),
      );
    }

    return ImportTable(name: '$schoolName-$termName', courses: courses);
  }

  static String _cleanText(String? input) {
    return (input ?? '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .trim();
  }

  static List<int> _parseWeeks(String text) {
    final String normalized = text.replaceAll('，', ',').replaceAll(' ', '');
    if (normalized.isEmpty) {
      return <int>[];
    }

    final List<int> result = <int>[];
    for (final String segment0 in normalized.split(',')) {
      String segment = segment0;
      final bool oddOnly = segment.contains('单');
      final bool evenOnly = segment.contains('双');
      segment = segment.replaceAll(RegExp(r'[()（）单双]'), '');

      if (segment.contains('-')) {
        final List<String> parts = segment.split('-');
        final int start = int.tryParse(parts.first) ?? 0;
        final int end = int.tryParse(parts.last) ?? 0;
        if (start <= 0 || end <= 0 || end < start) {
          continue;
        }
        for (int week = start; week <= end; week++) {
          if (oddOnly && week % 2 == 0) {
            continue;
          }
          if (evenOnly && week % 2 == 1) {
            continue;
          }
          result.add(week);
        }
      } else {
        final int single = int.tryParse(segment) ?? 0;
        if (single > 0) {
          result.add(single);
        }
      }
    }

    final List<int> unique = result.toSet().toList()..sort();
    return unique;
  }

  static int _parseTimeCount(String sectionExpr, int rowSection) {
    final String normalized = sectionExpr.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    if (normalized.contains('-')) {
      final List<String> parts = normalized.split('-');
      final int start = int.tryParse(parts.first.trim()) ?? rowSection;
      final int end = int.tryParse(parts.last.trim()) ?? rowSection;
      if (end < start) {
        return 0;
      }
      return end - start + 1;
    }

    final int value = int.tryParse(normalized) ?? 0;
    if (value <= 0) {
      return 0;
    }

    // XJTU page often renders duplicated rows and stores the section end in this field.
    if (value >= rowSection) {
      return value - rowSection + 1;
    }
    return 1;
  }
}
