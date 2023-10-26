import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/screens/loading/firebase.dart';
import 'package:poke/screens/loading/initialize_app.dart';
import 'package:get_it/get_it.dart';

import 'initialize_app_test.mocks.dart';

(MockPokeFirebase, StreamController<User?>) mockFirebase() {
  final mockFirebase = MockPokeFirebase();

  // auth
  final mockAuth = MockFirebaseAuth();
  final userStreamController = StreamController<User?>();
  when(mockAuth.userChanges()).thenAnswer((_) => userStreamController.stream);
  when(mockFirebase.auth()).thenReturn(mockAuth);

  // crashlytics
  final mockCrashlytics = MockFirebaseCrashlytics();
  when(mockFirebase.crashlytics()).thenReturn(mockCrashlytics);

  // firestore
  final mockFirestore = MockFirebaseFirestore();
  when(mockFirebase.firestore()).thenReturn(mockFirestore);

  // app check
  final mockAppCheck = MockFirebaseAppCheck();
  when(mockFirebase.appCheck()).thenReturn(mockAppCheck);

  return (mockFirebase, userStreamController);
}

@GenerateMocks([
  PokeFirebase,
  FirebaseAuth,
  User,
  FirebaseCrashlytics,
  FirebaseFirestore,
  FirebaseAppCheck,
], customMocks: [
  MockSpec<NavigatorState>(onMissingStub: OnMissingStub.returnDefault)
])
void main() {
  GetIt.instance.allowReassignment = true;

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

    verify(nav.pushReplacement(toLoginScreen)).called(1);
  });

  test('auth listener navigates to home screen when logged in', () async {
    final (firebaseMock, userStream) = mockFirebase();

    final nav = MockNavigatorState();
    await initializeApp(firebase: firebaseMock, nav: nav);

    userStream.add(MockUser());
    // wait until listeners have had a chance to react
    await Future.delayed(Duration.zero);

    verify(nav.pushReplacement(toHomeScreen)).called(1);
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
}
