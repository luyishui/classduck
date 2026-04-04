import 'package:classduck_app/features/import/domain/school_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchoolConfig.fromMap', () {
    test('maps fields from payload', () {
      final SchoolConfig config = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'xjtu',
        'level': 'general',
        'title': '西安交通大学',
        'initialUrl': 'https://example.edu/login',
        'targetUrl': 'https://example.edu/table',
        'extractScriptUrl': '/api/schools/xjtu/script',
        'delaySeconds': 2,
      });

      expect(config.id, 'xjtu');
      expect(config.level, 'general');
      expect(config.title, '西安交通大学');
      expect(config.delaySeconds, 2);
    });

    test('normalizes junior to undergraduate', () {
      final SchoolConfig config = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'foo',
        'level': 'junior',
        'title': '某高职学院',
      });

      expect(config.level, 'undergraduate');
    });

    test('infers master when level is missing', () {
      final SchoolConfig config = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'bar',
        'title': '某大学研究生院',
      });

      expect(config.level, 'master');
    });

    test('normalizes display title from AIS suffix', () {
      final SchoolConfig config = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'ais_whu',
        'level': 'undergraduate',
        'title': '武汉大学（AIShedule）',
      });

      expect(config.displayTitle, '武汉大学');
    });

    test('normalizes display title from system suffix', () {
      final SchoolConfig config = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'ruc',
        'level': 'master',
        'title': '中国人民大学研究生教育信息系统',
      });

      expect(config.displayTitle, '中国人民大学');
    });

    test('keeps jiaowu suffix for general entries', () {
      final SchoolConfig config = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'generic-zhengfang',
        'level': 'general',
        'title': '正方教务',
      });

      expect(config.displayTitle, '正方教务');
    });

    test('preserves campus qualifier for branch campuses', () {
      final SchoolConfig config = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'neuq',
        'level': 'undergraduate',
        'title': '东北大学秦皇岛分校树维教务',
      });

      expect(config.displayTitle, '东北大学秦皇岛分校');
    });

    test('parses execution school ids and exposes executable chain', () {
      final SchoolConfig config = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'wakeup_type_zf',
        'level': 'general',
        'title': '正方教务',
        'executionSchoolIds': <String>['zhengfang_01', 'zhengfang_01', ''],
      });

      expect(config.executionSchoolIds, <String>['zhengfang_01']);
      expect(config.executableSchoolIds, <String>['zhengfang_01']);
    });

    test('falls back executable chain to self id when not configured', () {
      final SchoolConfig config = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'zhengfang_01',
        'level': 'general',
        'title': '正方教务html通用获取',
      });

      expect(config.executionSchoolIds, isEmpty);
      expect(config.executableSchoolIds, <String>['zhengfang_01']);
    });
  });
}
