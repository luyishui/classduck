import 'package:classduck_app/features/import/data/school_config_repository.dart';
import 'package:classduck_app/features/import/domain/school_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchoolConfigRepository.decodeBuiltinPayload', () {
    test('parses payload with UTF-8 BOM prefix', () {
      const String raw =
          '\uFEFF{"version":"2026-04-03","data":[{"id":"ais_whu","level":"undergraduate","title":"武汉大学","initialUrl":"https://example.edu/login","targetUrl":"","extractScriptUrl":"/api/schools/ais_whu/script?script_type=provider","delaySeconds":0}]}';

      final configs = SchoolConfigRepository.decodeBuiltinPayload(raw);

      expect(configs, hasLength(1));
      expect(configs.first.id, 'ais_whu');
      expect(configs.first.level, 'undergraduate');
    });
  });

  group('SchoolConfigRepository.dedupeByDisplayTitle', () {
    test('keeps single entry for same school and level', () {
      final List<SchoolConfig> source = <SchoolConfig>[
        SchoolConfig.fromMap(<String, dynamic>{
          'id': 'school-055-郑州大学',
          'level': 'undergraduate',
          'title': '郑州大学',
          'initialUrl': 'https://example.com/login',
          'targetUrl': 'https://example.com/course',
          'extractScriptUrl': 'local://parsers/school-generic.js',
          'delaySeconds': 3,
        }),
        SchoolConfig.fromMap(<String, dynamic>{
          'id': 'ais_zzu',
          'level': 'undergraduate',
          'title': '郑州大学（AIShedule）',
          'initialUrl': '',
          'targetUrl': '',
          'extractScriptUrl':
              '/api/schools/ais_zzu/script?script_type=provider',
          'delaySeconds': 0,
        }),
      ];

      final List<SchoolConfig> deduped =
          SchoolConfigRepository.dedupeByDisplayTitle(source);

      expect(deduped, hasLength(1));
      expect(deduped.first.id, 'ais_zzu');
      expect(deduped.first.displayTitle, '郑州大学');
    });

    test('keeps richer RUC master config when duplicate exists', () {
      final List<SchoolConfig> source = <SchoolConfig>[
        SchoolConfig.fromMap(<String, dynamic>{
          'id': 'school-066-中国人民大学',
          'level': 'master',
          'title': '中国人民大学',
          'initialUrl': 'https://yjs2.ruc.edu.cn',
          'targetUrl': 'https://yjs2.ruc.edu.cn',
          'extractScriptUrl': 'local://parsers/school-generic.js',
          'delaySeconds': 3,
        }),
        SchoolConfig.fromMap(<String, dynamic>{
          'id': 'csf_zhongguorenmindaxuejiaowu',
          'level': 'master',
          'title': '中国人民大学研究生教育信息系统',
          'initialUrl': 'https://yjs2.ruc.edu.cn',
          'targetUrl':
              'https://yjs2.ruc.edu.cn/gsapp/sys/wdkbapp/*default/index.do',
          'extractScriptUrl':
              '/api/schools/csf_zhongguorenmindaxuejiaowu/script?script_type=provider',
          'delaySeconds': 3,
        }),
      ];

      final List<SchoolConfig> deduped =
          SchoolConfigRepository.dedupeByDisplayTitle(source);

      expect(deduped, hasLength(1));
      expect(deduped.first.id, 'csf_zhongguorenmindaxuejiaowu');
      expect(deduped.first.displayTitle, '中国人民大学');
    });

    test('keeps wakeup alias and hides shiguang conflict after fusion', () {
      final List<SchoolConfig> source = <SchoolConfig>[
        SchoolConfig.fromMap(<String, dynamic>{
          'id': 'wakeup_type_zf',
          'level': 'general',
          'title': '正方教务',
          'executionSchoolIds': <String>['zhengfang_01'],
          'initialUrl': '',
          'targetUrl': '',
          'extractScriptUrl': '',
          'delaySeconds': 0,
        }),
        SchoolConfig.fromMap(<String, dynamic>{
          'id': 'zhengfang_01',
          'level': 'general',
          'title': '正方教务html通用获取',
          'initialUrl': '',
          'targetUrl': '',
          'extractScriptUrl':
              '/api/schools/zhengfang_01/script?script_type=provider',
          'delaySeconds': 0,
        }),
      ];

      final List<SchoolConfig> fused =
          SchoolConfigRepository.fuseGeneralWakeupRules(source);

      expect(fused, hasLength(1));
      expect(fused.first.id, 'wakeup_type_zf');
      expect(fused.first.executableSchoolIds, <String>['zhengfang_01']);
    });
  });
}
