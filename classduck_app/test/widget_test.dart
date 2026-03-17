import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:classduck_app/app/app.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('app shell loads tab navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ClassDuckApp());
    await tester.pump(const Duration(seconds: 7));

    expect(find.text('课表'), findsOneWidget);
    expect(find.text('待办'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
