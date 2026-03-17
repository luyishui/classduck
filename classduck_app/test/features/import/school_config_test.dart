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
  });
}