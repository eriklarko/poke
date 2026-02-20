import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mockito/mockito.dart';

import 'mocks.dart';

/// Helper used to test things related to HTTP, like if an URL was hit or that
/// the correct image is shown in the ui.
///
/// Usage:
///  testWidgets('http endpoint is hit', (tester) async {
///     const url = 'https://example.com/test-image.png';
///
///     // set up the mock HTTP client, mapping urls to responses
///     final httpClient = TestHttpClient(endpoints: {
///       // when `url` is hit, return an image
///       url: () => base64Decode(
///             'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
///           ),
///     });
///
///     // wrap your test in `httpClient.run`, making sure to await it if your test is async
///     await httpClient.run(() async {
///       // make network call
///       await tester.pumpWidget(Image.network(url));
///
///       // ensure correct url was hit
///       expect(
///         httpClient.hitCount(url),
///         equals(1),
///       );
///     });
///   });
class TestHttpClient extends MockHttpClient {
  final Map<String, int> _hitCounts = {};

  TestHttpClient({Map<String, Uint8List Function()>? endpoints}) {
    when(getUrl(any)).thenAnswer((Invocation invocation) {
      final url = invocation.positionalArguments[0].toString();
      _hitCounts.update(url, (hitCount) => hitCount + 1, ifAbsent: () => 1);

      final request = MockHttpClientRequest();
      if (endpoints != null && endpoints.containsKey(url)) {
        _mockRequestResponse(
          request: request,
          responseData: endpoints[url]!.call(),
        );
      }

      return Future<HttpClientRequest>.value(request);
    });
  }

  R run<R>(R Function() body) {
    return HttpOverrides.runZoned(
      body,
      createHttpClient: (_) => this,
    );
  }

  int hitCount(String url) {
    return _hitCounts[url] ?? 0;
  }

  // taken from network_image_mock; see license in ./mocks.dart
  void _mockRequestResponse({
    required MockHttpClientRequest request,
    required Uint8List responseData,
  }) {
    final MockHttpClientResponse response = MockHttpClientResponse();
    final MockHttpHeaders headers = MockHttpHeaders();
    when(request.headers).thenReturn(headers);
    when(request.close())
        .thenAnswer((_) => Future<HttpClientResponse>.value(response));
    when(response.compressionState)
        .thenReturn(HttpClientResponseCompressionState.notCompressed);
    when(response.contentLength).thenReturn(responseData.length);
    when(response.statusCode).thenReturn(HttpStatus.ok);
    when(response.listen(
      any,
      onError: anyNamed("onError"),
      onDone: anyNamed("onDone"),
      cancelOnError: anyNamed("cancelOnError"),
    )).thenAnswer((Invocation invocation) {
      final void Function(List<int>) onData = invocation.positionalArguments[0];
      final onDone = invocation.namedArguments[#onDone];
      final onError = invocation.namedArguments[#onError];
      final bool? cancelOnError = invocation.namedArguments[#cancelOnError];

      return Stream<List<int>>.fromIterable(<List<int>>[responseData]).listen(
        onData,
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError,
      );
    });
  }
}
