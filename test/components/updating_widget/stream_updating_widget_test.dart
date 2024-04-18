import 'dart:async';

import 'package:flutter/widgets.dart' hide Overlay;
import 'package:flutter_test/flutter_test.dart';
import 'package:poke/components/updating_widget/overlay.dart';
import 'package:poke/components/updating_widget/stream_updating_widget.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_text.dart';

import '../../test_app.dart';

void main() {
  testWidgets('initial state', (tester) async {
    await pumpInTestApp(
      tester,
      StreamUpdatingWidget<String>(
        initialData: "foo",
        dataStream: const Stream.empty(),
        buildChild: (context, data) => PokeText(data),
      ),
    );

    expect(find.text('foo'), findsOneWidget);
    expect(find.byType(Overlay), findsNothing);
  });

  testWidgets('nullable initial state', (tester) async {
    await pumpInTestApp(
      tester,
      // Note the generic type `String?`, allowing `initialData: null`
      StreamUpdatingWidget<String?>(
        initialData: null,
        dataStream: const Stream.empty(),
        buildChild: (context, data) => PokeText(data ?? 'no data'),
      ),
    );

    expect(find.text('no data'), findsOneWidget);
    expect(find.byType(Overlay), findsNothing);
  });

  testWidgets('shows updated state', (tester) async {
    final sc = StreamController<String?>();
    await pumpInTestApp(
      tester,
      StreamUpdatingWidget<String>(
        initialData: "initial data",
        dataStream: sc.stream,
        buildChild: (context, data) => PokeText(data),
      ),
    );

    sc.add("updated data");
    await tester.pump();

    expect(find.text('updated data'), findsOneWidget);
    expect(find.byType(Overlay), findsNothing);
  });

  testWidgets('loading state', (tester) async {
    final sc = StreamController<String?>();
    await pumpInTestApp(
      tester,
      StreamUpdatingWidget<String>(
        initialData: "foo",
        dataStream: sc.stream,
        buildChild: (context, data) => PokeText(data),
      ),
    );

    // enter loading state
    sc.add(null);
    await tester.pump();

    // ensure child is rendered
    expect(find.text('foo'), findsOneWidget);

    // and that a spinner is shown
    expect(find.byType(Overlay), findsOneWidget);
    expect(find.byType(PokeLoadingIndicator), findsOneWidget);
  });

  testWidgets('error state', (tester) async {
    final sc = StreamController<String?>();
    await pumpInTestApp(
      tester,
      SizedBox.expand(
        child: StreamUpdatingWidget<String>(
          initialData: "foo",
          dataStream: sc.stream,
          buildChild: (context, data) => PokeText(data),
        ),
      ),
    );

    // enter error state
    sc.addError('some error');
    await tester.pumpAndSettle();

    // ensure child is rendered
    expect(find.text('foo'), findsOneWidget);

    // and that the error is shown
    expect(find.byType(Overlay), findsOneWidget);
    expect(find.textContaining('some error'), findsOneWidget);
  });
}
