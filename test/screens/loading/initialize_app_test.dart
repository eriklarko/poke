import 'dart:async';

import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:clock/clock.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/notifications/awesome_notifications.dart';
import 'package:poke/persistence/firebase_firestore_persistence.dart';
import 'package:poke/screens/auth/login_screen.dart';
import 'package:poke/screens/home_screen.dart';
import 'package:poke/screens/loading/poke_firebase.dart';
import 'package:poke/screens/loading/initialize_app.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/in_memory_notification_platform.dart';
import '../../utils/dependencies.dart';
import '../../utils/test-action/test_action.dart';
import 'initialize_app_test.mocks.dart';

(MockPokeFirebase, StreamController<User?>) mockFirebase() {
  final mockFirebase = MockPokeFirebase();

  // auth
  final mockAuth = MockFirebaseAuth();
  when(mockAuth.currentUser).thenReturn(MockUser());
  final userStreamController = StreamController<User?>();
  when(mockAuth.userChanges()).thenAnswer((_) => userStreamController.stream);
  when(mockFirebase.auth()).thenReturn(mockAuth);

  // crashlytics
  final mockCrashlytics = MockFirebaseCrashlytics();
  when(mockFirebase.crashlytics()).thenReturn(mockCrashlytics);

  // firestore
  final mockFirestore = FakeFirebaseFirestore();
  when(mockFirebase.firestore()).thenReturn(mockFirestore);

  // app check
  final mockAppCheck = MockFirebaseAppCheck();
  when(mockFirebase.appCheck()).thenReturn(mockAppCheck);

  return (mockFirebase, userStreamController);
}

@GenerateNiceMocks([
  MockSpec<PokeFirebase>(),
  MockSpec<FirebaseAuth>(),
  MockSpec<User>(),
  MockSpec<FirebaseCrashlytics>(),
  MockSpec<FirebaseAppCheck>(),
  MockSpec<NavigatorState>(onMissingStub: OnMissingStub.returnDefault),
])
void main() {
  GetIt.instance.allowReassignment = true;
  SharedPreferences.setMockInitialValues({});

  test('initializes firebase', () async {
    final (m, _) = mockFirebase();
    when(m.initializeApp()).thenAnswer((_) => Future.value(null));

    await initializeApp(firebase: m, nav: MockNavigatorState());

    verify(m.initializeApp()).called(1);
  });

  test('auth listener navigates to login screen when logged out', () async {
    final (firebaseMock, userStream) = mockFirebase();

    final nav = MockNavigatorState();
    await initializeApp(firebase: firebaseMock, nav: nav);

    userStream.add(null);
    // wait until listeners have had a chance to react
    await Future.delayed(Duration.zero);

    verify(nav.pushReplacement(
      argThat(MatchesRouteType(LoginScreen)),
    )).called(1);
  });

  test('auth listener navigates to home screen when logged in', () async {
    final (firebaseMock, userStream) = mockFirebase();

    final nav = MockNavigatorState();
    await initializeApp(firebase: firebaseMock, nav: nav);

    userStream.add(MockUser());
    // wait until listeners have had a chance to react
    await Future.delayed(Duration.zero);

    verify(nav.pushReplacement(
      argThat(MatchesRouteType(HomeScreen)),
    )).called(1);
  });

  testWidgets('sends unhandled exceptions to crashlytics', (tester) async {
    // disable FlutterError so that we can throw expections in the test without
    // it exiting immediately. Store a ref to the original version of the error
    // handler so that we can restore it once the exception has been thrown;
    // otherwise the output from `expect(...)` won't be printed
    final originalflutterError = FlutterError.onError;
    FlutterError.onError = null;

    // set up app with a button that throws when tapped
    final expected = Exception('I pressed a button!');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TextButton(
          key: const Key('1'),
          onPressed: () {
            throw expected;
          },
          child: const Text('cause error'),
        ),
      ),
    ));

    // register crash handlers
    final (firebaseMock, _) = mockFirebase();
    await initializeApp(firebase: firebaseMock, nav: MockNavigatorState());

    // cause error
    await tester.tap(find.byKey(const Key('1')));

    // restore FlutterError to show `expect(...)` output
    FlutterError.onError = originalflutterError;

    // grap a reference to the expection that was thrown
    final c = firebaseMock.crashlytics() as MockFirebaseCrashlytics;
    final actual = (verify(
      c.recordFlutterFatalError(captureAny),
    ).captured.first as FlutterErrorDetails)
        .exception;

    // check that the expection thrown was the correct one
    expect(actual, equals(expected));
  });

  test('FlutterError.onError records crashlytics error', () async {
    final (firebaseMock, _) = mockFirebase();

    await initializeApp(firebase: firebaseMock, nav: MockNavigatorState());

    final errorDetails = FlutterErrorDetails(exception: Exception('hello'));
    FlutterError.onError?.call(errorDetails);

    final c = firebaseMock.crashlytics();
    verify(c.recordFlutterFatalError(errorDetails)).called(1);
  });

  test('PlatformDispatcher forwards errors to crashlytics', () async {
    final (firebaseMock, _) = mockFirebase();

    await initializeApp(firebase: firebaseMock, nav: MockNavigatorState());

    final error = Exception('hello');
    PlatformDispatcher.instance.onError?.call(error, StackTrace.empty);

    final c = firebaseMock.crashlytics();
    verify(c.recordError(error, StackTrace.empty, fatal: true)).called(1);
  });

  test('registers notifications', () async {
    //
    // create action with enough data for reminders
    registerTestActions();
    final action = TestAction(id: '1');

    final (firebaseMock, userStream) = mockFirebase();
    await FirebaseFirestorePersistence(firebaseMock)
        .createAction(action.withEvents({
      DateTime.parse('1963-11-23 13:37'): null,
      DateTime.parse('1989-12-06 06:06'): null,
    }));

    //
    // Log in
    userStream.add(MockUser());

    //
    // allow notifications
    setUpDevicePersistence();
    await setReminderService();
    AwesomeNotificationsPlatform.instance = InMemoryNotificationPlatform();
    final notificationService = AwesomeNotificationsService();
    await notificationService.initialize();
    await notificationService.decidePermissionsToSendNotifications();

    //
    // act, with a clock that returns a time before both timestamps above so
    // that the notifications aren't removed because the due date has passed
    await withClock(Clock.fixed(DateTime.parse("1900-01-01")), () async {
      await initializeApp(firebase: firebaseMock, nav: MockNavigatorState());
      // wait until listeners have had a chance to react
      await Future.delayed(Duration.zero);
    });

    //
    // check that notifications are registered
    final notifications =
        await notificationService.getAllScheduledNotifications();
    final actionsWithNotifications = notifications.map((n) => n.$1);
    expect(
      actionsWithNotifications,
      equals([action.equalityKey]),
    );
  });

  test('can be retried', () async {
    final (firebaseMock, _) = mockFirebase();
    final nav = MockNavigatorState();

    await initializeApp(firebase: firebaseMock, nav: nav);
    await initializeApp(firebase: firebaseMock, nav: nav);
  });
}

class MockBuildContext extends Mock implements BuildContext {}

class MatchesRouteType extends Matcher {
  final Type expected;

  MatchesRouteType(this.expected);

  @override
  Description describe(Description description) {
    return description;
  }

  @override
  bool matches(item, Map matchState) {
    if (item is! MaterialPageRoute) {
      return false;
    }

    final renderedWidget = item.builder(MockBuildContext());
    return renderedWidget.runtimeType == expected;
  }
}
