import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/screens/loading/loading_screen.dart';

import '../../mock_callback.dart';

void main() {
  testWidgets('renders loading indicator', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoadingScreen(
        loadingFuture: Future.value(null),
      ),
    ));

    expect(find.byType(PokeLoadingIndicator), findsOneWidget);
  });

  testWidgets('calls onLoadingDone when finished', (tester) async {
    final mockCallback = MockNoArgCallback();

    await tester.pumpWidget(MaterialApp(
      home: LoadingScreen(
        loadingFuture: Future.value(null),
        onLoadingDone: mockCallback,
      ),
    ));

    verify(mockCallback()).called(1);
  });

  testWidgets('throws if loading future fails', (tester) async {
    // wrap test in runZonedGuarded or `completer.completeError(..)` will cause
    // the test to exit immediately
    await runZonedGuarded(() async {
      final mockCallback = MockNoArgCallback();
      final c = Completer();

      // render loading screen
      await tester.pumpWidget(MaterialApp(
        home: LoadingScreen(
          loadingFuture: c.future,
          onLoadingDone: mockCallback,
        ),
      ));

      // cause loadingFuture to fail
      c.completeError('foo');
      await tester.pump();

      // check that onLoadingDone was never called
      verifyNever(mockCallback());
    }, (error, stack) {
      // By checking that the expected error was thrown here we avoid
      // incorrectly passing the test if future was stuck in waiting forever
      expectSync(error, equals("foo"));
    });
  });
}
