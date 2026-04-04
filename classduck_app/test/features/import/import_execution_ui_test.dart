import 'package:classduck_app/features/import/application/import_engine.dart';
import 'package:classduck_app/features/import/domain/school_config.dart';
import 'package:classduck_app/features/import/ui/import_execution_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('import execution helpers', () {
    test('normalizeImportUrl keeps absolute URLs and fixes bare host', () {
      expect(normalizeImportUrl('https://example.edu'), 'https://example.edu');
      expect(normalizeImportUrl('jw.example.edu'), 'https://jw.example.edu');
      expect(normalizeImportUrl('   '), '');
    });

    test('inferImportTermTokens picks first semester in autumn', () {
      final tokens = inferImportTermTokens(<String, dynamic>{
        'first': '3',
        'second': '12',
      }, now: DateTime(2026, 9, 1));

      expect(tokens['year'], '2026');
      expect(tokens['term'], '3');
    });

    test('inferImportTermTokens picks second semester in spring', () {
      final tokens = inferImportTermTokens(<String, dynamic>{
        'first': '3',
        'second': '12',
      }, now: DateTime(2026, 3, 1));

      expect(tokens['year'], '2025');
      expect(tokens['term'], '12');
    });

    test('shouldEnableGeneralSurveyFlow covers all general-level systems', () {
      final SchoolConfig generalConfig = SchoolConfig.fromMap(<String, dynamic>{
        'id': 'custom_general_system_01',
        'level': 'general',
        'title': '自定义通用教务',
        'initialUrl': 'https://example.com/login',
        'targetUrl': '',
        'extractScriptUrl': '/api/schools/custom/script?script_type=provider',
        'delaySeconds': 0,
      });

      expect(shouldEnableGeneralSurveyFlow(generalConfig), isTrue);
    });
  });

  testWidgets('GeneralImportSurveyDialog success confirms survey action', (
    WidgetTester tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) =>
                        const GeneralImportSurveyDialog.success(),
                  );
                },
                child: const Text('open-success'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open-success'));
    await tester.pumpAndSettle();

    expect(find.text('导入成功，邀请共建'), findsOneWidget);
    expect(find.text('去填问卷'), findsOneWidget);

    await tester.tap(find.text('去填问卷'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('GeneralImportSurveyDialog failure confirms survey action', (
    WidgetTester tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) =>
                        const GeneralImportSurveyDialog.failure(),
                  );
                },
                child: const Text('open-failure'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open-failure'));
    await tester.pumpAndSettle();

    expect(find.text('一起补齐适配'), findsOneWidget);
    expect(find.text('去填问卷'), findsOneWidget);

    await tester.tap(find.text('去填问卷'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('ImportWebFallbackPanel renders message and button', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportWebFallbackPanel(
            onOpen: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Web 端不支持内嵌教务网页'), findsOneWidget);
    expect(find.text('在浏览器中打开教务网站'), findsOneWidget);

    await tester.tap(find.text('在浏览器中打开教务网站'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('ImportConflictDialog exposes three import choices', (
    WidgetTester tester,
  ) async {
    ImportConflictMode? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<ImportConflictMode>(
                    context: context,
                    builder: (BuildContext context) =>
                        const ImportConflictDialog(),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('课表导入冲突处理'), findsOneWidget);
    expect(find.text('新建课表'), findsOneWidget);
    expect(find.text('覆盖原有课表'), findsOneWidget);
    expect(find.text('新增课程（追加到当前课表）'), findsOneWidget);

    await tester.tap(find.text('新增课程（追加到当前课表）'));
    await tester.pumpAndSettle();

    expect(result, ImportConflictMode.appendToCurrent);
  });

  testWidgets('ImportConflictDialog keeps overwrite action behavior', (
    WidgetTester tester,
  ) async {
    ImportConflictMode? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<ImportConflictMode>(
                    context: context,
                    builder: (BuildContext context) =>
                        const ImportConflictDialog(),
                  );
                },
                child: const Text('open-overwrite'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open-overwrite'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('覆盖原有课表'));
    await tester.pumpAndSettle();

    expect(result, ImportConflictMode.overwriteExisting);
  });
}
