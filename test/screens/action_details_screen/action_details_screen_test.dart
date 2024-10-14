import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/screens/action_details_screen/action_details_screen.dart';
import 'package:poke/screens/home_screen.dart';
import 'package:poke/utils/nav_service.dart';

import '../../test_app.dart';
import '../../utils/dependencies.dart';
import '../../utils/test-action/test_action.dart';
import 'action_details_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NavigatorObserver>()])
void main() {
  testWidgets('shows when the next notification is scheduled', (tester) async {
    //// Set up state for the test
    // create action with enough data to show the notification
    final action = TestAction(id: "1");
    final dueDate = DateTime.parse('1963-11-23');

    // create a notification for the action
    setNotificationService();
    final sut = GetIt.instance.get<NotificationService>();
    await sut.scheduleReminder(action, dueDate);

    // set up ActionDetailsScreen dependencies
    setPersistence(InMemoryPersistence());

    //// Render the widget
    await pumpInTestApp(
      tester,
      ActionDetailsScreen(
        action: action,
        body: PokeText("foo"),
      ),
    );
    await tester.pumpAndSettle();

    // check that the notification is shown with its due date
    expect(find.textContaining("1963-11-23"), findsOneWidget);
  });

  testWidgets("navigates to home screen after deleting action", (tester) async {
    registerTestActions();

    //// Set up state for the test
    // create action to delete
    final action = TestAction(id: "1");

    // set up ActionDetailsScreen dependencies
    final persistence = InMemoryPersistence();
    persistence.createAction(action);
    setPersistence(persistence);
    setNotificationService();
    setReminderService();

    //// Render the widget
    await tester.pumpWidget(MaterialApp(
      navigatorKey: NavService.internal.key,
      home: ActionDetailsScreen(
        action: action,
        body: PokeText("foo"),
      ),
    ));
    await tester.pumpAndSettle();

    // tap the delete button
    await tester.tap(find.text("Delete action"));
    await tester.pumpAndSettle();

    // tap the confirmation dialog's yes button
    await tester.tap(find.text("DELETE NOW"));
    await tester.pumpAndSettle();

    // check that the home screen is shown
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

class LolMatcher extends Matcher {
  const LolMatcher();

  @override
  bool matches(covariant Finder finder, Map<dynamic, dynamic> matchState) {
    return true;
  }

  @override
  Description describe(Description description) => description.add('lol');
}
