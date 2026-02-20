import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/screens/notifications_list/notifications_list_screen.dart';

import '../../test_app.dart';
import '../../utils/dependencies.dart';
import '../../utils/test-action/test_action.dart';

void main() {
  testWidgets('shows scheduled notifications', (tester) async {
    registerTestActions();

    final action1 = TestAction(id: '1');
    final action2 = TestAction(id: '2');

    final persistence = InMemoryPersistence();
    persistence.createAction(action1);
    persistence.createAction(action2);
    setPersistence(persistence);

    await withClock(Clock.fixed(DateTime.parse('1963-11-23')), () async {
      // schedule two notifictions
      final notifService = setNotificationService();
      await notifService.scheduleReminder(
        action1,
        clock.now().add(Duration(days: -1)),
      );
      await notifService.scheduleReminder(
        action2,
        clock.now().add(Duration(days: -2)),
      );

      await pumpInTestApp(tester, NotificationsListScreen());
      await tester.pumpAndSettle();

      expect(find.text('Test action 1'), findsOneWidget);
      expect(find.text('Test action 2'), findsOneWidget);
    });
  });
}
