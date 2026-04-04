import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tt_check/src/app.dart';
import 'package:tt_check/src/storage/storage.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    hiveDirectory = await Directory.systemTemp.createTemp('tt_check_test_');
    Hive.init(hiveDirectory.path);
    await Storage.openBoxes();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  testWidgets('app shows primary navigation tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const TTCheckApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
  });
}
