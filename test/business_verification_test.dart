import 'package:fixmate/app_state.dart';
import 'package:fixmate/pages/business_verification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget verificationTestApp(AppState state) => ChangeNotifierProvider.value(
  value: state,
  child: const MaterialApp(home: BusinessVerificationPage(allowSkip: true)),
);

void main() {
  testWidgets(
    'supplier pending review explains the approval wait and blocks skip',
    (tester) async {
      final state = AppState()
        ..userRole = 'Supplier'
        ..businessVerificationStatus = 'submitted';

      await tester.pumpWidget(verificationTestApp(state));

      expect(find.text('Documents under review'), findsOneWidget);
      expect(find.textContaining('up to 24 hours'), findsOneWidget);
      expect(find.text('Skip for now'), findsNothing);
    },
  );

  testWidgets(
    'rejected technician review displays the reason and required files',
    (tester) async {
      final state = AppState()
        ..userRole = 'Technician'
        ..businessVerificationStatus = 'rejected'
        ..businessVerificationReviewNote = 'Upload a clearer photo of your ID.'
        ..verificationRequiredServices = ['Plumbing'];

      await tester.pumpWidget(verificationTestApp(state));

      expect(
        find.textContaining('Upload a clearer photo of your ID.'),
        findsOneWidget,
      );
      expect(find.text('Certificate or license: Plumbing'), findsOneWidget);
      expect(find.text('Government ID card (front)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Submit for review'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Submit for review'), findsOneWidget);
    },
  );

  testWidgets('verification history shows submission and rejection notes', (
    tester,
  ) async {
    final state = AppState()
      ..userRole = 'Technician'
      ..businessVerificationStatus = 'rejected'
      ..verificationRequiredServices = ['Plumbing']
      ..businessVerificationHistory = [
        BusinessVerificationHistoryEntry(
          id: 'history-1',
          eventType: 'rejected',
          note: 'Provide a clearer ID image.',
          createdAt: DateTime(2026, 10, 12),
        ),
        BusinessVerificationHistoryEntry(
          id: 'history-2',
          eventType: 'submitted',
          note: null,
          createdAt: DateTime(2026, 10, 10),
        ),
      ];

    await tester.pumpWidget(verificationTestApp(state));
    await tester.scrollUntilVisible(
      find.text('Verification history'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Verification history'), findsOneWidget);
    expect(find.text('Changes requested'), findsOneWidget);
    expect(find.textContaining('Provide a clearer ID image.'), findsOneWidget);
    expect(find.text('Documents submitted'), findsOneWidget);
  });
}
