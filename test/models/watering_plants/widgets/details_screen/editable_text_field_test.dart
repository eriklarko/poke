import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/models/watering_plants/widgets/action_screen/editable_text_field.dart';

import '../../../../mock_callback.dart';
import '../../../../test_app.dart';

void main() {
  testWidgets('displays initial text', (WidgetTester tester) async {
    await pumpInTestApp(tester, EditableTextField('Initial Text'));
    expect(find.text('Initial Text'), findsOneWidget);
  });

  testWidgets('enters edit mode when edit button is pressed', (
    WidgetTester tester,
  ) async {
    await pumpInTestApp(tester, EditableTextField('Initial Text'));

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    expect(find.text('Initial Text'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });

  testWidgets('saves edited text', (WidgetTester tester) async {
    final onChanged = MockSingleArgCallback<String>();

    await pumpInTestApp(
      tester,
      EditableTextField(
        'Initial Text',
        onChanged: onChanged.call,
      ),
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Edited Text');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    expect(find.text('Edited Text'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);

    verify(onChanged('Edited Text')).called(1);
  });

  testWidgets('cancels edit mode', (WidgetTester tester) async {
    final onChanged = MockSingleArgCallback<String>();

    await pumpInTestApp(
      tester,
      EditableTextField(
        'Initial Text',
        onChanged: onChanged.call,
      ),
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Edited Text');
    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pump();

    expect(find.text('Initial Text'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);

    verifyNever(onChanged('Edited Text'));
  });

  testWidgets(
      'shows loading spinner and error state with async onChanged callback', (
    WidgetTester tester,
  ) async {
    await pumpInTestApp(
      tester,
      EditableTextField(
        'Initial Text',
        onChanged: (newText) async {
          await Future.delayed(Duration(seconds: 1));
          throw Exception('Error');
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Edited Text');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    // Verify loading spinner is shown
    expect(find.byType(PokeLoadingIndicator), findsOneWidget);

    // Wait for the async operation to complete
    await tester.pumpAndSettle();

    // Verify error state is shown
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
  });
}
