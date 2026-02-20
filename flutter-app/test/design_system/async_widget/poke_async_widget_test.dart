import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/async_widget/state.dart';

import '../../test_app.dart';

final unimportantWidget = Container();

void main() {
  Widget testBuilder(context, PokeAsyncWidgetState state) {
    return switch (state) {
      Idle() => Container(
          key: const Key('idle'),
        ),
      Loading() => Container(
          key: const Key('loading'),
        ),
      Success() => Container(
          key: const Key('success'),
        ),
      Error() => Container(
          key: const Key('error'),
          child: Text(state.error),
        ),
    };
  }

  testWidgets("renders idle state on first render", (tester) async {
    final controller = PokeAsyncWidgetController();

    await pumpInTestApp(
      tester,
      PokeAsyncWidget(
        controller: controller,
        builder: testBuilder,
      ),
    );

    expect(find.byKey(const Key("idle")), findsOneWidget);
  });

  testWidgets("renders loading state after calling controller.setLoading()",
      (tester) async {
    final controller = PokeAsyncWidgetController();

    await pumpInTestApp(
      tester,
      PokeAsyncWidget(
        controller: controller,
        builder: testBuilder,
      ),
    );

    controller.setLoading();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("loading")), findsOneWidget);
  });

  testWidgets("renders success state after calling controller.setSuccessful()",
      (tester) async {
    final controller = PokeAsyncWidgetController();

    await pumpInTestApp(
      tester,
      PokeAsyncWidget(
        controller: controller,
        builder: testBuilder,
      ),
    );

    controller.setSuccessful();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("success")), findsOneWidget);
  });

  testWidgets("renders error state after calling controller.setErrored()",
      (tester) async {
    final controller = PokeAsyncWidgetController();

    await pumpInTestApp(
      tester,
      PokeAsyncWidget(
        controller: controller,
        builder: testBuilder,
      ),
    );

    controller.setErrored("some-error");
    await tester.pumpAndSettle();

    expect(find.byKey(const Key("error")), findsOneWidget);
    expect(find.text("some-error"), findsOneWidget);
  });

  group('Using the simple constructor', () {
    testWidgets('shows idle state initially', (tester) async {
      final controller = PokeAsyncWidgetController();

      const idleWidgetKey = Key('1');
      await pumpInTestApp(
        tester,
        PokeAsyncWidget.simple(
          controller: controller,
          idle: Container(
            key: idleWidgetKey,
          ),
          loading: unimportantWidget,
          error: (_) => unimportantWidget,
        ),
      );

      expect(find.byKey(idleWidgetKey), findsOneWidget);
    });

    testWidgets('switches to loading state', (tester) async {
      final controller = PokeAsyncWidgetController();

      const loadingWidgetKey = Key('1');
      await pumpInTestApp(
        tester,
        PokeAsyncWidget.simple(
          controller: controller,
          idle: unimportantWidget,
          loading: Container(
            key: loadingWidgetKey,
          ),
          error: (_) => unimportantWidget,
        ),
      );

      controller.setLoading();
      await tester.pumpAndSettle();

      expect(find.byKey(loadingWidgetKey), findsOneWidget);
    });

    testWidgets('shows success widget if one is supplied', (tester) async {
      final controller = PokeAsyncWidgetController();

      const successWidgetKey = Key('1');
      await pumpInTestApp(
        tester,
        PokeAsyncWidget.simple(
          controller: controller,
          idle: unimportantWidget,
          loading: unimportantWidget,
          success: Container(
            key: successWidgetKey,
          ),
          error: (_) => unimportantWidget,
        ),
      );

      controller.setSuccessful();
      await tester.pumpAndSettle();

      expect(find.byKey(successWidgetKey), findsOneWidget);
    });

    testWidgets(
      'shows idle widget in success state if no success widget is supplied',
      (tester) async {
        final controller = PokeAsyncWidgetController();

        const idleWidgetKey = Key('1');
        await pumpInTestApp(
          tester,
          PokeAsyncWidget.simple(
            controller: controller,
            loading: unimportantWidget,
            idle: Container(
              key: idleWidgetKey,
            ),
            // no success widget supplied, could leave this prop out as well
            success: null,
            error: (_) => unimportantWidget,
          ),
        );

        controller.setSuccessful();
        await tester.pumpAndSettle();

        expect(find.byKey(idleWidgetKey), findsOneWidget);
      },
    );

    testWidgets('shows error widget and message', (tester) async {
      final controller = PokeAsyncWidgetController<String>();

      await pumpInTestApp(
        tester,
        PokeAsyncWidget<String>.simple(
          controller: controller,
          idle: unimportantWidget,
          loading: unimportantWidget,
          error: (errorMsg) => Text(errorMsg),
        ),
      );

      controller.setErrored('oh no!');
      await tester.pumpAndSettle();

      expect(find.text('oh no!'), findsOneWidget);
    });
  });
}
