import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:poke/components/reminder_list/updating_reminder_list_item.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/action_with_events.dart';

import '../../mock_callback.dart';
import '../../test_app.dart';
import '../../utils/test-action/test_action.dart';

final MockSingleArgCallback ignoreCallback = MockSingleArgCallback();

void main() {
  testWidgets('shows initial data at first', (tester) async {
    await pumpInTestApp(
      tester,
      UpdatingReminderListItem(
        initialData: Reminder(
          actionWithEvents: ActionWithEvents.single(
            TestActionWithData(),
            DateTime.now(),
            data: Data("initial-data"),
          ),
          dueDate: null,
        ),
        dataStream: StreamController<Reminder?>().stream,
        onTap: ignoreCallback,
        onSnooze: ignoreCallback,
      ),
    );

    expect(find.text('initial-data'), findsOneWidget);
  });

  testWidgets('shows loading indicator when `null` is sent on updates stream',
      (tester) async {
    final sc = StreamController<Reminder?>();
    await pumpInTestApp(
      tester,
      UpdatingReminderListItem(
        initialData: Reminder(
          actionWithEvents: ActionWithEvents(TestAction()),
          dueDate: null,
        ),
        dataStream: sc.stream,
        onTap: ignoreCallback,
        onSnooze: ignoreCallback,
      ),
    );

    // verify that no loading indicator is shown yet
    expect(find.byType(PokeLoadingIndicator), findsNothing);

    // send `null` to trigger loading indicator
    sc.add(null);
    await tester.pump();

    expect(find.byType(PokeLoadingIndicator), findsOneWidget);
  });

  testWidgets('rerenders when new reminder is received', (tester) async {
    final sc = StreamController<Reminder?>();
    final reminder = Reminder(
      actionWithEvents: ActionWithEvents.single(
        TestActionWithData(),
        DateTime.now(),
        data: Data("initial-data"),
      ),
      dueDate: null,
    );

    await pumpInTestApp(
      tester,
      UpdatingReminderListItem(
        initialData: reminder,
        dataStream: sc.stream,
        onTap: ignoreCallback,
        onSnooze: ignoreCallback,
      ),
    );

    final updatedReminder = Reminder(
      actionWithEvents: reminder.actionWithEvents.copy().add(
            DateTime.now(),
            eventData: Data('updated-data'),
          ),
      dueDate: reminder.dueDate,
    );
    sc.add(updatedReminder);
    await tester.pump();

    expect(find.text('updated-data'), findsOneWidget);
  });

  testWidgets('shows last known data under loading indicator while updating',
      (tester) async {
    final sc = StreamController<Reminder?>();
    await pumpInTestApp(
      tester,
      UpdatingReminderListItem(
        initialData: Reminder(
          actionWithEvents: ActionWithEvents.single(
            TestActionWithData(),
            DateTime.now(),
            data: Data("initial-data"),
          ),
          dueDate: null,
        ),
        dataStream: sc.stream,
        onTap: ignoreCallback,
        onSnooze: ignoreCallback,
      ),
    );

    // send `null` to trigger loading indicator
    sc.add(null);
    await tester.pump();

    expect(find.text('initial-data'), findsOneWidget);
    expect(find.byType(PokeLoadingIndicator), findsOneWidget);
  });
}
