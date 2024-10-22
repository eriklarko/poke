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

    // schedule two notifictions
    final notifService = setNotificationService();
    await notifService.scheduleReminder(action1, DateTime.parse('1963-11-23'));
    await notifService.scheduleReminder(action2, DateTime.parse('1989-12-06'));

    await pumpInTestApp(tester, NotificationsListScreen());
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.textContaining('1963-11-23'), findsOneWidget);

    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('1989-12-06'), findsOneWidget);
  });
}
