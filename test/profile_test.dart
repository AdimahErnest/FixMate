import 'package:fixmate/app_state.dart';
import 'package:fixmate/pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final role in ['Technician', 'Supplier']) {
    testWidgets('$role profile displays ratings', (tester) async {
      final state = AppState()..userRole = role;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountDetails(state: state, t: (value) => value),
          ),
        ),
      );

      expect(find.text('My ratings: '), findsOneWidget);
      expect(find.text('No ratings yet'), findsOneWidget);
    });
  }

  testWidgets('customer profile does not display ratings', (tester) async {
    final state = AppState()..userRole = 'Customer';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountDetails(state: state, t: (value) => value),
        ),
      ),
    );

    expect(find.text('My ratings: '), findsNothing);
    expect(find.text('4.8'), findsNothing);
  });
}
