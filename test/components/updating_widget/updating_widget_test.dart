import 'package:flutter_test/flutter_test.dart';
import 'package:poke/components/updating_widget/overlay.dart';
import 'package:poke/components/updating_widget/updating_widget.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_text.dart';

import '../../test_app.dart';

void main() {
  testWidgets('initial state', (tester) async {
    final controller = UpdatingWidgetController();
    await pumpInTestApp(
      tester,
      UpdatingWidget(
        controller: controller,
        buildChild: (context) => PokeText('foo'),
      ),
    );

    expect(find.text('foo'), findsOneWidget);
    expect(find.byType(Overlay), findsNothing);
  });

  testWidgets('loading state', (tester) async {
    final controller = UpdatingWidgetController();
    await pumpInTestApp(
      tester,
      UpdatingWidget(
        controller: controller,
        buildChild: (context) => PokeText('foo'),
      ),
    );

    // enter loading state
    controller.setLoading();
    await tester.pump();

    // ensure child is rendered
    expect(find.text('foo'), findsOneWidget);

    // and that a spinner is shown
    expect(find.byType(Overlay), findsOneWidget);
    expect(find.byType(PokeLoadingIndicator), findsOneWidget);
  });

  testWidgets('error state', (tester) async {
    final controller = UpdatingWidgetController();
    await pumpInTestApp(
      tester,
      UpdatingWidget(
        controller: controller,
        buildChild: (context) => PokeText('foo'),
      ),
    );

    // enter loading state
    controller.setError('some error');
    await tester.pumpAndSettle();

    // ensure child is rendered
    expect(find.text('foo'), findsOneWidget);

    // and that the error is shown
    expect(find.byType(Overlay), findsOneWidget);
    expect(find.textContaining('some error'), findsOneWidget);
  });
}
