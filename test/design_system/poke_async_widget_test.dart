import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/design_system/poke_async_widget.dart';

import '../test_app.dart';

final unimportantWidget = Container();

void main() {
  testWidgets('shows idle state initially', (tester) async {
    final controller = PokeAsyncWidgetController();

    const idleWidgetKey = Key('1');
    await pumpInTestApp(
      tester,
      PokeAsyncWidget(
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
      PokeAsyncWidget(
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
      PokeAsyncWidget(
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
        PokeAsyncWidget(
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
      PokeAsyncWidget<String>(
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
}
