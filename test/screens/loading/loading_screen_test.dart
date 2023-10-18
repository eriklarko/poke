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
    await runZonedGuarded(() async {
      final mockCallback = MockNoArgCallback();
      final c = Completer();

      await tester.pumpWidget(MaterialApp(
        home: LoadingScreen(
          loadingFuture: c.future,
          onLoadingDone: mockCallback,
        ),
      ));

      c.completeError('foo');
      await tester.pump();

      verifyNever(mockCallback());
    }, (error, stack) {
      expectSync(error, equals("foo"));
    });
  });
}
