import 'package:flutter/material.dart';
import 'package:flutter_crdt_sync_kit_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows both device panels and lets Device A edit the shared todo',
    (tester) async {
      await tester.pumpWidget(const SyncKitDemoApp());
      await tester.pumpAndSettle();

      expect(find.text('Device A'), findsOneWidget);
      expect(find.text('Device B'), findsOneWidget);
      expect(find.text('Save'), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).first, 'Buy oat milk');
      await tester.tap(find.text('Save').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Buy oat milk'), findsWidgets);
    },
  );
}
