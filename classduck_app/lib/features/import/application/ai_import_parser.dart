import 'dart:convert';

import '../domain/import_course.dart';
import '../domain/import_table.dart';

class AiImportParser {
  static const String _defaultTableName = 'AI导入课表';

  static ImportTable parse(
    String source, {
    String fallbackTableName = _defaultTableName,
  }) {
    final dynamic decoded = jsonDecode(_extractJsonPayload(source));
    final Map<String, dynamic> root = _normalizeRoot(decoded);
    final List<dynamic> rawCourses = _extractCourses(root);
    final List<ImportCourse> courses = rawCourses
        .whereType<Map>()
        .map(_stringKeyedMap)
        .map(_parseCourse)
        .toList(growable: false);

    if (courses.isEmpty) {
      throw const FormatException('未识别到可导入课程，请确认 AI 只返回课程 JSON。');
    }

    final String tableName =
        _pickString(root, const <String>[
          'table_name',
          'tableName',
          'semester_name',
          'semesterName',
          'schedule_name',
          'scheduleName',
          'name',
          'title',
        ]) ??
        fallbackTableName;

    return ImportTable(
      name: tableName.trim().isEmpty ? fallbackTableName : tableName.trim(),
      courses: courses,
    );
  }

  static Map<String, dynamic> _normalizeRoot(dynamic decoded) {
    if (decoded is List) {
      return <String, dynamic>{'courses': decoded};
    }

    if (decoded is! Map) {
      throw const FormatException('AI 返回内容不是 JSON 对象或数组。');
    }

    final Map<String, dynamic> root = _stringKeyedMap(decoded);
    final dynamic data = root['data'];

    if (data is List) {
      return <String, dynamic>{...root, 'courses': data};
    }
    if (data is Map) {
      final Map<String, dynamic> nested = _normalizeRoot(data);
      return <String, dynamic>{...root, ...nested};
    }

    return root;
  }

  static List<dynamic> _extractCourses(Map<String, dynamic> root) {
    final List<String> candidateKeys = <String>[
      'courses',
      'course_list',
      'courseList',
      'class_list',
      'classList',
      'result',
      'rows',
      'schedule',
      'items',
      'course',
      'item',
    ];

    for (final String key in candidateKeys) {
      final dynamic candidate = root[key];
      if (candidate is List) {
        return candidate;
      }
      if (candidate is Map && _looksLikeCourse(candidate)) {
        return <dynamic>[candidate];
      }
    }

    if (_looksLikeCourse(root)) {
      return <dynamic>[root];
    }

    throw const FormatException('未找到 courses 数组，请确认提示词要求 AI 只返回 JSON。');
  }

  static bool _looksLikeCourse(Map<dynamic, dynamic> raw) {
    final Map<String, dynamic> map = _stringKeyedMap(raw);
    final bool hasName =
        _pickString(map, const <String>[
          'n',
          'name',
          'course_name',
          'courseName',
        ]) !=
        null;
    final bool hasDay =
        map.containsKey('d') ||
        map.containsKey('day') ||
        map.containsKey('weekday') ||
        map.containsKey('week_day') ||
        map.containsKey('weekDay');
    final bool hasWeek =
        map.containsKey('w') ||
        map.containsKey('weeks') ||
        map.containsKey('week_list') ||
      map.containsKey('weekList') ||
      map.containsKey('week_schedule') ||
      map.containsKey('week schedule') ||
      map.containsKey('weekschedule') ||
      map.containsKey('weekSchedule');
    final bool hasSection =
        map.containsKey('s') ||
        map.containsKey('start_section') ||
        map.containsKey('startSection') ||
      map.containsKey('startNode') ||
        map.containsKey('sections');
    return hasName && hasDay && hasWeek && hasSection;
  }

  static ImportCourse _parseCourse(Map<String, dynamic> raw) {
    final String name =
        (_pickString(raw, const <String>[
                  'n',
                  'name',
                  'course_name',
                  'courseName',
                  'title',
                  '课程名',
                  '课程名称',
                ]) ??
                '')
            .trim();
    if (name.isEmpty) {
      throw const FormatException('存在课程缺少名称，请重新生成 AI 结果。');
    }

    final List<int> weeks = _parseWeeks(
      raw['w'] ??
          raw['weeks'] ??
          raw['week_list'] ??
          raw['weekList'] ??
          raw['week_schedule'] ??
          raw['week schedule'] ??
          raw['weekschedule'] ??
          raw['weekSchedule'] ??
          raw['week_range'] ??
          raw['weekRange'] ??
          raw['week_text'] ??
          raw['weekText'] ??
          raw['周次'],
    );
    if (weeks.isEmpty) {
      throw FormatException('课程 $name 缺少周次信息。');
    }

    final int weekDay = _parseWeekDay(
      raw['d'] ??
          raw['day'] ??
          raw['weekday'] ??
          raw['week_day'] ??
          raw['weekDay'] ??
          raw['星期'] ??
          raw['周几'],
    );

    final List<int>? sectionRange = _parseSectionRange(
      raw['sections'] ??
          raw['section_range'] ??
          raw['sectionRange'] ??
          raw['节次'] ??
          raw['上课节次'],
    );

    final int? startSection =
        _parsePositiveInt(
          raw['s'] ??
              raw['start_section'] ??
              raw['startSection'] ??
              raw['startNode'] ??
              raw['start_node'] ??
              raw['start'] ??
              raw['开始节'] ??
              raw['开始小节'],
        ) ??
        sectionRange?.first;
    final int? endSection =
        _parsePositiveInt(
          raw['e'] ??
              raw['end_section'] ??
              raw['endSection'] ??
              raw['endNode'] ??
              raw['end_node'] ??
              raw['end'] ??
              raw['结束节'] ??
              raw['结束小节'],
        ) ??
        sectionRange?.last;

    int? timeCount = _parsePositiveInt(
      raw['duration'] ??
          raw['time_count'] ??
          raw['timeCount'] ??
          raw['period_count'] ??
          raw['periodCount'] ??
          raw['节数'] ??
          raw['课时'],
    );
    if (timeCount == null && startSection != null && endSection != null) {
      final int from = startSection <= endSection ? startSection : endSection;
      final int to = startSection <= endSection ? endSection : startSection;
      timeCount = to - from + 1;
    }

    if (startSection == null || startSection <= 0) {
      throw FormatException('课程 $name 缺少开始节次。');
    }
    if (timeCount == null || timeCount <= 0) {
      throw FormatException('课程 $name 缺少有效节次数。');
    }

    return ImportCourse(
      name: name,
      classroom: _nullableString(raw, const <String>[
        'l',
        'classroom',
        'room',
        'location',
        'position',
        '教室',
        '地点',
      ]),
      classNumber: _nullableString(raw, const <String>[
        'class_number',
        'classNumber',
        'class_no',
        'classNo',
        '课程序号',
      ]),
      teacher: _nullableString(raw, const <String>[
        't',
        'teacher',
        'instructor',
        '老师',
        '教师',
      ]),
      weeks: weeks,
      weekTime: weekDay,
      startTime: startSection,
      timeCount: timeCount,
    );
  }

  static String _extractJsonPayload(String source) {
    final String trimmed = source.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('请先粘贴 AI 返回结果。');
    }

    final List<String> candidates = <String>[];
    final Iterable<RegExpMatch> blockMatches = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    ).allMatches(trimmed);
    for (final RegExpMatch match in blockMatches) {
      final String? block = match.group(1)?.trim();
      if (block != null && block.isNotEmpty) {
        candidates.add(block);
      }
    }

    candidates.add(trimmed);

    final int objectStart = trimmed.indexOf('{');
    final int objectEnd = trimmed.lastIndexOf('}');
    if (objectStart >= 0 && objectEnd > objectStart) {
      candidates.add(trimmed.substring(objectStart, objectEnd + 1));
    }

    final int listStart = trimmed.indexOf('[');
    final int listEnd = trimmed.lastIndexOf(']');
    if (listStart >= 0 && listEnd > listStart) {
      candidates.add(trimmed.substring(listStart, listEnd + 1));
    }

    for (final String candidate in candidates) {
      try {
        jsonDecode(candidate);
        return candidate;
      } catch (_) {
        continue;
      }
    }

    throw const FormatException('未找到可解析的 JSON，请确认复制的是 AI 原始结果。');
  }

  static String? _pickString(Map<String, dynamic> raw, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = raw[key];
      if (value == null) {
        continue;
      }
      final String text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static String? _nullableString(Map<String, dynamic> raw, List<String> keys) {
    final String? value = _pickString(raw, keys);
    if (value == null) {
      return null;
    }
    const Set<String> emptyMarkers = <String>{
      'null',
      'NULL',
      '无',
      '暂无',
      '-',
      '/',
      '未填写',
      '未安排',
    };
    return emptyMarkers.contains(value) ? null : value;
  }

  static int _parseWeekDay(dynamic value) {
    final int? numeric = _parsePositiveInt(value);
    if (numeric != null && numeric >= 1 && numeric <= 7) {
      return numeric;
    }

    final String normalized = (value ?? '').toString().trim();
    const Map<String, int> mapping = <String, int>{
      '周一': 1,
      '星期一': 1,
      '周二': 2,
      '星期二': 2,
      '周三': 3,
      '星期三': 3,
      '周四': 4,
      '星期四': 4,
      '周五': 5,
      '星期五': 5,
      '周六': 6,
      '星期六': 6,
      '周日': 7,
      '周天': 7,
      '星期日': 7,
      '星期天': 7,
    };

    for (final MapEntry<String, int> entry in mapping.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    throw FormatException('无法识别上课星期: $normalized');
  }

  static int? _parsePositiveInt(dynamic value) {
    if (value is int) {
      return value > 0 ? value : null;
    }
    if (value is double) {
      final int result = value.round();
      return result > 0 ? result : null;
    }
    if (value == null) {
      return null;
    }

    final RegExpMatch? match = RegExp(r'\d+').firstMatch(value.toString());
    if (match == null) {
      return null;
    }
    final int parsed = int.parse(match.group(0)!);
    return parsed > 0 ? parsed : null;
  }

  static List<int>? _parseSectionRange(dynamic value) {
    if (value is List) {
      final List<int> sections = value
          .map(_parsePositiveInt)
          .whereType<int>()
          .toList(growable: false);
      if (sections.isEmpty) {
        return null;
      }
      return <int>[sections.first, sections.last];
    }

    if (value == null) {
      return null;
    }

    final String normalized = value
        .toString()
        .replaceAll('第', '')
        .replaceAll('节', '')
        .replaceAll('大节', '')
        .replaceAll('小节', '')
        .replaceAll(' ', '')
        .replaceAll('到', '-')
        .replaceAll('至', '-')
        .replaceAll('~', '-')
        .replaceAll('—', '-');
    final RegExpMatch? rangeMatch = RegExp(
      r'(\d+)(?:-(\d+))?',
    ).firstMatch(normalized);
    if (rangeMatch == null) {
      return null;
    }

    final int start = int.parse(rangeMatch.group(1)!);
    final int end = int.parse(rangeMatch.group(2) ?? rangeMatch.group(1)!);
    final int from = start <= end ? start : end;
    final int to = start <= end ? end : start;
    return <int>[from, to];
  }

  static List<int> _parseWeeks(dynamic value) {
    if (value is List) {
      final List<int> merged = <int>[];
      for (final dynamic item in value) {
        merged.addAll(_parseWeeks(item));
      }
      return _distinctSorted(merged);
    }

    if (value is int) {
      return value > 0 ? <int>[value] : const <int>[];
    }

    if (value == null) {
      return const <int>[];
    }

    final String normalized = value
        .toString()
        .trim()
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('第', '')
        .replaceAll('周次', '')
        .replaceAll('周', '')
        .replaceAll(' ', '')
        .replaceAll('，', ',')
        .replaceAll('、', ',')
        .replaceAll('；', ',')
        .replaceAll(';', ',')
        .replaceAll('｜', ',')
        .replaceAll('|', ',')
        .replaceAll('/', ',')
        .replaceAll('～', '-')
        .replaceAll('~', '-')
        .replaceAll('至', '-')
        .replaceAll('到', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-');

    if (normalized.isEmpty) {
      return const <int>[];
    }

    if (normalized.startsWith('[') && normalized.endsWith(']')) {
      try {
        final dynamic decoded = jsonDecode(normalized);
        if (decoded is List) {
          return _parseWeeks(decoded);
        }
      } catch (_) {
        // Ignore invalid embedded JSON and continue with textual parsing.
      }
    }

    final List<int> weeks = <int>[];
    for (final String rawSegment in normalized.split(',')) {
      if (rawSegment.isEmpty) {
        continue;
      }

      final bool oddOnly = rawSegment.contains('单');
      final bool evenOnly = rawSegment.contains('双');
      final Iterable<RegExpMatch> matches = RegExp(
        r'(\d+)(?:-(\d+))?',
      ).allMatches(rawSegment);
      for (final RegExpMatch match in matches) {
        final int start = int.parse(match.group(1)!);
        final int end = int.parse(match.group(2) ?? match.group(1)!);
        final int from = start <= end ? start : end;
        final int to = start <= end ? end : start;

        if (oddOnly || evenOnly) {
          int current = from;
          if (oddOnly && current.isEven) {
            current += 1;
          }
          if (evenOnly && current.isOdd) {
            current += 1;
          }
          while (current <= to) {
            weeks.add(current);
            current += 2;
          }
        } else {
          for (int current = from; current <= to; current++) {
            weeks.add(current);
          }
        }
      }
    }

    return _distinctSorted(weeks);
  }

  static List<int> _distinctSorted(List<int> values) {
    final Set<int> filtered = values.where((int item) => item > 0).toSet();
    final List<int> result = filtered.toList(growable: false)..sort();
    return result;
  }

  static Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> raw) {
    return raw.map(
      (dynamic key, dynamic value) => MapEntry(key.toString(), value),
    );
  }
}
