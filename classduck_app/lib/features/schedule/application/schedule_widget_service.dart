import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../data/schedule_repository.dart';
import '../domain/course.dart';
import '../domain/course_table.dart';

/// 桌面小组件数据同步服务。
///
/// 【设计原则】Flutter 引擎在桌面小组件渲染时并不运行，因此这里只负责把
/// 活跃课表的全量结构（节次时间表 + 全部课程）打包成紧凑 JSON，经
/// home_widget 写入 Android SharedPreferences（key: widget_schedule_data）。
/// 原生 Glance 引擎在系统桌面进程内用本地时钟做纯算术推导，App 无需保活。
class ScheduleWidgetService {
  ScheduleWidgetService._();

  /// SharedPreferences 中全量课表数据的 key（与原生端约定一致）。
  static const String widgetDataKey = 'widget_schedule_data';

  /// 三个规格小组件接收器的完整类名。
  static const List<String> _receiverClassNames = <String>[
    'io.github.luyishui.classduck.widget.ClassDuckSmallWidgetReceiver',
    'io.github.luyishui.classduck.widget.ClassDuckMediumWidgetReceiver',
    'io.github.luyishui.classduck.widget.ClassDuckLargeWidgetReceiver',
  ];

  /// 课程颜色兜底调色板（与 App 内 _colorForCourseName 保持一致）。
  static const List<String> _fallbackPalette = <String>[
    '#D45E6A',
    '#CBA42F',
    '#4A88D2',
    '#B6C223',
    '#896ED8',
    '#2AA4A2',
    '#D68152',
    '#A19586',
  ];

  /// App 内旧版课程色板 → 新版色板的 1:1 归一映射。
  static const Map<String, String> _legacyColorMapping = <String, String>{
    '#EAA4AF': '#D45E6A',
    '#F2C27D': '#CBA42F',
    '#A9CDFE': '#4A88D2',
    '#9ED9A2': '#B6C223',
    '#C7C1F8': '#896ED8',
    '#8FD8D0': '#2AA4A2',
    '#F5B57A': '#D68152',
    '#D9C1A5': '#A19586',
  };

  static bool get _isAndroidSupported {
    if (kIsWeb) {
      return false;
    }
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// 同步去抖间隔：批量导入/连续编辑时合并刷新，避免高频写
  /// SharedPreferences 与广播风暴。
  static const Duration _syncDebounceInterval = Duration(milliseconds: 500);
  static Timer? _syncDebounceTimer;

  /// 触发小组件数据同步。
  ///
  /// 默认带 500ms 尾沿去抖——同一突发内的多次触发只执行最后一次，
  /// 且执行时重新读取最新数据；[immediate] 为 true 时跳过去抖立即执行，
  /// 用于 App 切后台等需要确定性落盘的兜底场景。
  static void syncCurrentScheduleToWidget({bool immediate = false}) {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = null;
    if (immediate) {
      unawaited(_performSync());
      return;
    }
    _syncDebounceTimer = Timer(_syncDebounceInterval, () {
      unawaited(_performSync());
    });
  }

  /// 将当前活跃课表全量下发到桌面小组件。
  ///
  /// 任何失败都不应影响主流程，仅记录日志。无课表时下发空数据让
  /// 小组件展示空状态。
  static Future<void> _performSync() async {
    if (!_isAndroidSupported) {
      return;
    }
    try {
      final String? payload = await buildSchedulePayload();
      await HomeWidget.saveWidgetData<String>(widgetDataKey, payload);
      for (final String className in _receiverClassNames) {
        await HomeWidget.updateWidget(qualifiedAndroidName: className);
      }
    } catch (error) {
      debugPrint('[widget] sync schedule to widget failed: $error');
    }
  }

  /// 构建全量课表 JSON；无可用课表时返回 null（清除小组件数据）。
  @visibleForTesting
  static Future<String?> buildSchedulePayload() async {
    final ScheduleRepository repository = ScheduleRepository();
    final List<CourseTableEntity> tables = await repository.getCourseTables();
    if (tables.isEmpty) {
      return null;
    }

    final int? preferredId = ScheduleRepository.activeTableId;
    CourseTableEntity active = tables.first;
    for (final CourseTableEntity table in tables) {
      if (table.id != null && table.id == preferredId) {
        active = table;
        break;
      }
    }
    if (active.id == null) {
      return null;
    }

    final List<CourseEntity> courses = await repository.getCoursesByTableId(
      active.id!,
    );
    final Map<String, Object?> config = _decodeTableConfig(
      active.classTimeListJson,
    );

    return jsonEncode(<String, Object?>{
      'tableId': active.id,
      'tableName': active.name,
      // 与 App 端 _ScheduleConfig.fromJson 的兜底语义一致：未配置开学日期时
      // 回填默认开学日（当年 9 月 2 日），保证原生端周次推导与 App 内一致。
      'semesterStartMonday':
          active.semesterStartMonday ?? _defaultSemesterStart(),
      'termWeeks': config['termWeeks'],
      'classDuration': config['classDuration'],
      'breakDuration': config['breakDuration'],
      'sections': config['sections'],
      'courses': courses
          .map((CourseEntity course) => _courseToJson(course))
          .toList(growable: false),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 与 App 端 `_ScheduleConfig.defaults()` 同源：默认开学日为当年 9 月 2 日。
  static String _defaultSemesterStart() {
    final DateTime now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-09-02';
  }

  /// 复刻 App 端 `_ScheduleConfig.defaults()` 的默认作息：
  /// 上午 4 节（08:00 起）、下午 4 节（14:00 起）、晚上 2 节（19:00 起），
  /// 每节 45 分钟，节间休息 10 分钟。
  @visibleForTesting
  static List<Map<String, String>> defaultSections() {
    final List<Map<String, String>> sections = <Map<String, String>>[];
    for (final (String anchor, int count) in <(String, int)>[
      ('08:00', 4),
      ('14:00', 4),
      ('19:00', 2),
    ]) {
      int cursor = _toMinutes(anchor);
      for (int i = 0; i < count; i++) {
        sections.add(<String, String>{
          'start': _formatMinutes(cursor),
          'end': _formatMinutes(cursor + 45),
        });
        cursor += 45 + 10;
      }
    }
    return sections;
  }

  static int _toMinutes(String hhmm) {
    final List<String> parts = hhmm.split(':');
    final int h = int.tryParse(parts.first) ?? 0;
    final int m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return h * 60 + m;
  }

  static String _formatMinutes(int minute) {
    final int h = (minute ~/ 60) % 24;
    final int m = minute % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static Map<String, Object?> _courseToJson(CourseEntity course) {
    return <String, Object?>{
      'name': course.name.trim(),
      'classroom': _cleanOrNull(course.classroom),
      'teacher': _cleanOrNull(course.teacher),
      'weekTime': course.weekTime,
      'startTime': course.startTime,
      'timeCount': course.timeCount,
      'colorHex': resolveCourseColorHex(course),
      'weeks': _decodeWeeks(course.weeksJson),
    };
  }

  /// 解析课表作息配置 JSON；缺失或为空时回退到与 App 端一致的默认作息
  /// （App 端 `_ScheduleConfig.fromJson(null)` 会落到 defaults()，照常按周过滤）。
  static Map<String, Object?> _decodeTableConfig(String? rawJson) {
    Map<String, Object?> map = const <String, Object?>{};
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(rawJson);
        if (decoded is Map<String, Object?>) {
          map = decoded;
        } else if (decoded is Map) {
          map = decoded.map(
            (Object? key, Object? value) =>
                MapEntry<String, Object?>(key.toString(), value),
          );
        }
      } catch (_) {
        map = const <String, Object?>{};
      }
    }

    final List<Map<String, String>> sections = <Map<String, String>>[
      ..._parseSectionList(map['morningSections']),
      ..._parseSectionList(map['afternoonSections']),
      ..._parseSectionList(map['eveningSections']),
    ];
    final List<Map<String, String>> fallback = _parseSectionList(
      map['sections'],
    );
    final List<Map<String, String>> resolvedSections = sections.isNotEmpty
        ? sections
        : fallback;
    // 与 App 端 normalizeCounts() 一致：作息永不为空。
    final List<Map<String, String>> effectiveSections = resolvedSections
        .isNotEmpty
        ? resolvedSections
        : defaultSections();

    return <String, Object?>{
      'termWeeks': (map['termWeeks'] as num?)?.toInt() ?? 20,
      'classDuration': (map['classDuration'] as num?)?.toInt() ?? 45,
      'breakDuration': (map['breakDuration'] as num?)?.toInt() ?? 10,
      'sections': effectiveSections
          .asMap()
          .entries
          .map(
            (MapEntry<int, Map<String, String>> entry) => <String, Object?>{
              'index': entry.key + 1,
              'start': entry.value['start'],
              'end': entry.value['end'],
            },
          )
          .toList(growable: false),
    };
  }

  static List<Map<String, String>> _parseSectionList(Object? raw) {
    if (raw is! List) {
      return const <Map<String, String>>[];
    }
    final List<Map<String, String>> result = <Map<String, String>>[];
    for (final Object? item in raw) {
      if (item is Map) {
        final String? start = item['start']?.toString();
        final String? end = item['end']?.toString();
        if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
          result.add(<String, String>{'start': start, 'end': end});
        }
      }
    }
    return result;
  }

  /// weeksJson 存的是枚举后的周次数组（如 [1,2,3,...,16]）。
  static List<int> _decodeWeeks(String weeksJson) {
    try {
      final Object? decoded = jsonDecode(weeksJson);
      if (decoded is! List) {
        return const <int>[];
      }
      return decoded
          .whereType<num>()
          .map((num item) => item.toInt())
          .where((int value) => value > 0)
          .toList(growable: false);
    } catch (_) {
      return const <int>[];
    }
  }

  /// 复刻 App 内的课程取色逻辑：优先 colorHex，旧色板映射为新色板，
  /// 过浅的颜色加深处理，无色则按课程名哈希从兜底色板取色。
  @visibleForTesting
  static String resolveCourseColorHex(CourseEntity course) {
    final String? raw = course.colorHex?.trim();
    if (raw != null && raw.isNotEmpty) {
      final String normalized = raw.startsWith('#') ? raw : '#$raw';
      final String upper = normalized.toUpperCase();
      if (_legacyColorMapping.containsKey(upper)) {
        return _legacyColorMapping[upper]!;
      }
      if (RegExp(r'^#[0-9A-F]{6}$').hasMatch(upper)) {
        return _darkenIfTooLight(upper);
      }
    }
    final int hash = course.name.runes.fold<int>(0, (int v, int e) => v * 31 + e);
    final int index = hash.abs() % _fallbackPalette.length;
    return _fallbackPalette[index];
  }

  /// 与 App 内 `computeLuminance() > 0.58 时叠加 0x66000000` 的规则一致。
  /// Flutter 的 computeLuminance 采用 sRGB 线性化后加权（0.2126/0.7152/0.0722）。
  static String _darkenIfTooLight(String hex) {
    final int r = int.parse(hex.substring(1, 3), radix: 16);
    final int g = int.parse(hex.substring(3, 5), radix: 16);
    final int b = int.parse(hex.substring(5, 7), radix: 16);
    double linearize(int channel) {
      final double c = channel / 255;
      return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    final double luminance =
        0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
    if (luminance <= 0.58) {
      return hex;
    }
    const double alpha = 0x66 / 255;
    int blend(int channel) =>
        ((1 - alpha) * channel + alpha * 0).round().clamp(0, 255);
    final int nr = blend(r);
    final int ng = blend(g);
    final int nb = blend(b);
    return '#${_hex2(nr)}${_hex2(ng)}${_hex2(nb)}'.toUpperCase();
  }

  static String _hex2(int value) => value.toRadixString(16).padLeft(2, '0');

  static String? _cleanOrNull(String? raw) {
    final String trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
