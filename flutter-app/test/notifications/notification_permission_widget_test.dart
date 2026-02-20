import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/notifications/notification_permission_widget.dart';
import 'package:poke/notifications/notification_service.dart';

import '../test_app.dart';
import '../utils/dependencies.dart';
import 'notification_permission_widget_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NotificationService>()])
void main() {
  MockNotificationService setUpNotificationService({
    required FutureOr<PermissionResponse> permissionResponse,
  }) {
    final mockNotifService = MockNotificationService();
    setDependency<NotificationService>(mockNotifService);

    if (permissionResponse is Future) {
      when(mockNotifService.hasPermissionToSendNotifications())
          .thenAnswer((_) => permissionResponse);
    } else {
      when(mockNotifService.hasPermissionToSendNotifications())
          .thenReturn(permissionResponse);
    }

    return mockNotifService;
  }

  testWidgets('the decide button calls decide function', (tester) async {
    final mockNotifService = setUpNotificationService(
      permissionResponse: PermissionResponse.hasNotChosen,
    );

    await pumpInTestApp(tester, const NotificationPermissionWidget());

    await tester.tap(find.text('Decide!'));

    verify(mockNotifService.decidePermissionsToSendNotifications());
  });

  testWidgets('is shown if the user has not yet decided', (tester) async {
    setUpNotificationService(
      // the user has not chosen yet
      permissionResponse: PermissionResponse.hasNotChosen,
    );

    await pumpInTestApp(tester, const NotificationPermissionWidget());

    expect(
      find.byKey(NotificationPermissionWidget.widgetKey),
      findsOneWidget,
    );
  });

  testWidgets('is not shown if the user has decided already', (tester) async {
    setUpNotificationService(
      // the user has made their choice
      permissionResponse: PermissionResponse.allowed,
    );

    await pumpInTestApp(tester, const NotificationPermissionWidget());

    expect(
      find.byKey(NotificationPermissionWidget.widgetKey),
      findsNothing,
    );
  });

  group('reading permission is async', () {
    testWidgets('shows loading indicator', (tester) async {
      final c = Completer<PermissionResponse>();
      setUpNotificationService(permissionResponse: c.future);

      await pumpInTestApp(
        tester,
        const NotificationPermissionWidget(
          takeUpSpaceWhileLoading: true,
        ),
      );

      expect(
        find.byType(PokeLoadingIndicator),
        findsOneWidget,
      );
    });

    testWidgets('shows errors', (tester) async {
      // wrap test in runZonedGuarded or `completer.completeError(..)` will cause
      // the test to exit immediately because devx is great.
      await runZonedGuarded(() async {
        setUpNotificationService(
            permissionResponse: Future.error("some error"));

        await pumpInTestApp(
          tester,
          const NotificationPermissionWidget(),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('some error'),
          findsOneWidget,
        );
      }, (error, stack) {
        // By checking that the expected error was thrown here we avoid
        // incorrectly passing the test if future was stuck in waiting forever
        expectSync(error, equals("some error"));
      });
    });

    testWidgets(
      'shows widget when data is fetched successfully',
      (tester) async {
        setUpNotificationService(
          permissionResponse: Future.value(PermissionResponse.hasNotChosen),
        );

        await pumpInTestApp(
          tester,
          const NotificationPermissionWidget(),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(NotificationPermissionWidget.widgetKey),
          findsOneWidget,
        );
      },
    );
  });
}
