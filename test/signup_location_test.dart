import 'package:fixmate/app_state.dart';
import 'package:fixmate/widgets/signup_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('signup location town choices follow the selected region', (
    tester,
  ) async {
    String? region;
    String? town;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SignupLocationFields(
                region: region,
                town: town,
                onRegionChanged: (value) => setState(() {
                  region = value;
                  town = null;
                }),
                onTownChanged: (value) => setState(() => town = value),
              ),
            ),
          ),
        ),
      ),
    );

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    expect(dropdowns, findsNWidgets(2));
    expect(
      tester.widget<DropdownButtonFormField<String>>(dropdowns.at(1)).onChanged,
      isNull,
    );
    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Far North').last);
    await tester.pumpAndSettle();
    expect(region, 'Far North');

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    expect(find.text('Maroua'), findsOneWidget);
    await tester.tap(find.text('Maroua').last);
    await tester.pumpAndSettle();
    expect(town, 'Maroua');

    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Littoral').last);
    await tester.pumpAndSettle();
    expect(region, 'Littoral');
    expect(town, isNull);
  });
}
