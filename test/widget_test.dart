// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify hat the values of widget properties are correct.

import 'package:fixmate/app_state.dart';
import 'package:fixmate/pages/role_selection.dart';
import 'package:fixmate/theme.dart';
import 'package:fixmate/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('light theme uses a warm blush gradient with creamy cards', () {
    expect(FixMateTheme.lightTheme.scaffoldBackgroundColor, Colors.transparent);
    expect(FixMateTheme.backgroundGradient(Brightness.light).colors, [
      FixMateTheme.lightBackground,
      FixMateTheme.lightBackgroundEnd,
    ]);
    expect(FixMateTheme.lightTheme.cardTheme.color, FixMateTheme.lightSurface);
  });

  test('dark theme restores the original near-black palette', () {
    expect(FixMateTheme.backgroundGradient(Brightness.dark).colors, [
      const Color(0xFF101010),
      const Color(0xFF101010),
    ]);
    expect(
      FixMateTheme.darkTheme.scaffoldBackgroundColor,
      const Color(0xFF101010),
    );
    expect(FixMateTheme.darkTheme.cardTheme.color, const Color(0xFF1B1B1B));
    final shape =
        FixMateTheme.darkTheme.cardTheme.shape! as RoundedRectangleBorder;
    expect(shape.side.color, const Color(0xFF30302D));
    expect(FixMateTheme.darkTheme.colorScheme.primary, const Color(0xFFE0B85F));
    expect(FixMateTheme.buttonGold, const Color(0xFF8F6E32));
  });

  testWidgets('glass panel clips and blurs its content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FixMateTheme.lightTheme,
        home: const Scaffold(
          body: GlassPanel(child: Icon(Icons.location_on_outlined)),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
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
