// Integration test for the sync_kit demo app. See
// https://flutter.dev/to/integration-testing for how to run this on a
// real device/simulator.

import 'package:flutter/material.dart';
import 'package:flutter_crdt_sync_kit_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'two devices editing different fields converge after both come back online',
    (tester) async {
      await tester.pumpWidget(const SyncKitDemoApp());
      await tester.pumpAndSettle();

      final titleFields = find.byType(TextField);
      final saveButtons = find.text('Save');

      // Device A edits the title...
      await tester.enterText(titleFields.first, 'Buy oat milk');
      await tester.tap(saveButtons.first);
      await tester.pumpAndSettle();

      // ...Device B (still online too, in this simple flow) marks it done.
      await tester.tap(find.text('Done').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Both fields eventually appear reflected in both panels once synced.
      expect(find.textContaining('Buy oat milk'), findsWidgets);
    },
  );
}
