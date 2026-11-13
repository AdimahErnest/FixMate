import 'package:fixmate/app_state.dart';
import 'package:fixmate/widgets/signup_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('searchable signup choices filter and toggle selections', (
    tester,
  ) async {
    final selected = <String>{};

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SignupSearchableChoiceChips(
                options: const ['Electrical repair', 'Plumbing', 'Painting'],
                selected: selected,
                onChanged: (value) => setState(() {
                  if (!selected.add(value)) selected.remove(value);
                }),
                searchLabel: 'Search services',
                emptyLabel: 'No services found',
                selectionHint: 'Choose services',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Electrical repair'), findsOneWidget);
    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Painting'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'plumb');
    await tester.pumpAndSettle();
    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Electrical repair'), findsNothing);
    expect(find.text('Painting'), findsNothing);

    await tester.tap(find.text('Plumbing'));
    await tester.pumpAndSettle();
    expect(selected, contains('Plumbing'));

    await tester.enterText(find.byType(TextField), 'carpentry');
    await tester.pumpAndSettle();
    expect(find.text('No services found'), findsOneWidget);
  });
}
