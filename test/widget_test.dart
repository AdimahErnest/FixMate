// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify hat the values of widget properties are correct.

import 'package:fixmate/app_state.dart';
import 'package:fixmate/pages/role_selection.dart';
import 'package:fixmate/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('light theme uses a soft warm background with white cards', () {
    expect(
      FixMateTheme.lightTheme.scaffoldBackgroundColor,
      FixMateTheme.lightBackground,
    );
    expect(FixMateTheme.lightTheme.cardTheme.color, Colors.white);
  });

  testWidgets('admin role is available in login selection', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppState())],
        child: const MaterialApp(home: RoleSelectionForLoginPage()),
      ),
    );

    expect(find.text('Admin'), findsOneWidget);
    expect(
      find.text('Manage platform operations and approvals.'),
      findsOneWidget,
    );
  });
}
