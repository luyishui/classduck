import 'package:classduck_app/features/import/application/import_engine.dart';
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
      final tokens = inferImportTermTokens(
        <String, dynamic>{'first': '3', 'second': '12'},
        now: DateTime(2026, 9, 1),
      );

      expect(tokens['year'], '2026');
      expect(tokens['term'], '3');
    });

    test('inferImportTermTokens picks second semester in spring', () {
      final tokens = inferImportTermTokens(
        <String, dynamic>{'first': '3', 'second': '12'},
        now: DateTime(2026, 3, 1),
      );

      expect(tokens['year'], '2025');
      expect(tokens['term'], '12');
    });
  });

  testWidgets('ImportWebFallbackPanel renders message and button', (WidgetTester tester) async {
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

  testWidgets('ImportConflictDialog exposes both import choices', (WidgetTester tester) async {
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
                    builder: (BuildContext context) => const ImportConflictDialog(),
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
    expect(find.text('导入冲突处理'), findsOneWidget);

    await tester.tap(find.text('覆盖当前课表'));
    await tester.pumpAndSettle();

    expect(result, ImportConflictMode.overwriteExisting);
  });
}