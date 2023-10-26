import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/design_system/poke_future_builder.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';

import '../test_app.dart';

void main() {
  testWidgets('renders child when future has data', (tester) async {
    // set up system-under-test rendering the value of a Future
    final future = Future.value('hello');
    final sut = PokeFutureBuilder<String>(
      future: future,
      child: (futureValue) => Text(futureValue),
      error: (_, __) => const Text('error'),
    );

    // render system-under-test
    await pumpInTestApp(tester, sut);

    // tick some time to allow the future to resolve
    await tester.pumpAndSettle();

    // check that the future value was rendered
    expect(find.text('hello'), findsOneWidget);

    // and that the error and loading widgets are not shown
    expect(find.byType(PokeLoadingIndicator), findsNothing);
    expect(find.text('error'), findsNothing);
  });

  testWidgets('renders loading indicator while future is waiting',
      (tester) async {
    // set up system-under-test rendering the value of a Future
    final future =
        Future.delayed(const Duration(milliseconds: 2), () => 'hello');
    final sut = PokeFutureBuilder<String>(
      future: future,
      child: (_) => const Text('hello'),
      error: (_, __) => const Text('error'),
    );

    // render system-under-test
    await pumpInTestApp(tester, sut);

    // tick some time to allow the future to settle
    await tester.pump(const Duration(milliseconds: 1));

    // check that the loading indicator is shown
    expect(find.byType(PokeLoadingIndicator), findsOneWidget);

    // and that the error and child widgets are not shown
    expect(find.text('hello'), findsNothing);
    expect(find.text('error'), findsNothing);

    // gotta give the delayed future a chance to finish or flutter yells at you
    await tester.pumpAndSettle();
  });

  testWidgets('can show custom loading indicator', (tester) async {
    // set up system-under-test rendering the value of a Future
    final future =
        Future.delayed(const Duration(milliseconds: 2), () => 'hello');
    final sut = PokeFutureBuilder<String>(
      future: future,
      loadingWidget: const Text('loading'),
      child: (_) => const Text('hello'),
      error: (_, __) => const Text('error'),
    );

    // render system-under-test
    await pumpInTestApp(tester, sut);

    // tick some time to allow the future to settle
    await tester.pump(const Duration(milliseconds: 1));

    // check that the custom loading indicator is shown
    expect(find.text('loading'), findsOneWidget);
    expect(find.byType(PokeLoadingIndicator), findsNothing);

    // and that the error and child widgets are not shown
    expect(find.text('hello'), findsNothing);
    expect(find.text('error'), findsNothing);

    // gotta give the delayed future a chance to finish or flutter yells at you
    await tester.pumpAndSettle();
  });

  testWidgets('shows error message if no custom error widget is provided',
      (tester) async {
    final future =
        Future.delayed(const Duration(milliseconds: 1), () => throw 'no good');
    final sut = PokeFutureBuilder(
      future: future,
      child: (_) => const Text('hello'),
    );

    // render system-under-test
    await pumpInTestApp(tester, sut);

    // tick some time to allow the future to settle
    await tester.pumpAndSettle();

    // check that the error is shown
    expect(find.text('no good'), findsOneWidget);

    // and that the loading and child widgets are not shown
    expect(find.text('hello'), findsNothing);
    expect(find.byType(PokeLoadingIndicator), findsNothing);
  });

  testWidgets('supports custom error widgets', (tester) async {
    final future =
        Future.delayed(const Duration(milliseconds: 1), () => throw 'no good');
    final sut = PokeFutureBuilder(
      future: future,
      child: (_) => const Text('hello'),
      error: (error, _) => Text('error: $error'),
    );

    // render system-under-test
    await pumpInTestApp(tester, sut);

    // tick some time to allow the future to settle
    await tester.pumpAndSettle();

    // check that the custom error widget is shown
    expect(find.text('error: no good'), findsOneWidget);

    // and that the loading and child widgets are not shown
    expect(find.text('hello'), findsNothing);
    expect(find.byType(PokeLoadingIndicator), findsNothing);
  });

  testWidgets('passes the future to custom error widgets', (tester) async {
    final future =
        Future.delayed(const Duration(milliseconds: 1), () => throw 'no good');
    bool futureChecked = false;
    final sut = PokeFutureBuilder(
      future: future,
      child: (_) => const Text('hello'),
      error: (error, fut) {
        expect(fut, equals(future));
        futureChecked = true;
        return Text('error: $error');
      },
    );

    // render system-under-test
    await pumpInTestApp(tester, sut);

    // tick some time to allow the future to settle
    await tester.pumpAndSettle();

    expect(futureChecked, equals(true));
  });
}
