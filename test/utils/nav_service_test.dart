import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/utils/nav_service.dart';

import 'nav_service_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<NavigatorObserver>(onMissingStub: OnMissingStub.returnDefault)
])
void main() {
  testWidgets('can navigate', (tester) async {
    final navObserver = MockNavigatorObserver();

    // create app with our NavService registered using the `navigatorKey` prop
    await tester.pumpWidget(MaterialApp(
      navigatorKey: NavService.internal.key,
      navigatorObservers: [navObserver],
      home: const Scaffold(),
    ));

    // navigate to some route
    final route =
        MaterialPageRoute(builder: (_) => const Scaffold(key: Key('1')));
    NavService.instance.push(route);

    await tester.pumpAndSettle();

    // ensure navigation to expected route happened
    verify(navObserver.didPush(route, any)).called(1);

    // and that the new page is shown
    expect(find.byKey(const Key('1')), findsOneWidget);
  });
}
