// taken from network_image_mock
// BSD 3-Clause License
//
// Copyright (c) 2020, Stelynx
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'dart:async';
import 'dart:io';

import 'package:mockito/mockito.dart';

class MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri? url) {
    // ignore: invalid_use_of_visible_for_testing_member
    return super.noSuchMethod(
      Invocation.method(#getUrl, [url]),
      returnValue: Future.value(MockHttpClientRequest()),
    );
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return super.noSuchMethod(
      Invocation.method(#getUrl, [url]),
      returnValue: Future.value(MockHttpClientRequest()),
    );
  }
}

class MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  // ignore: invalid_use_of_visible_for_testing_member
  HttpHeaders get headers => super.noSuchMethod(Invocation.getter(#headers),
      returnValue: MockHttpHeaders());

  @override
  Future<HttpClientResponse> close() =>
      // ignore: invalid_use_of_visible_for_testing_member
      super.noSuchMethod(Invocation.method(#close, []),
          returnValue: Future.value(MockHttpClientResponse()));
}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  HttpClientResponseCompressionState get compressionState =>
      // ignore: invalid_use_of_visible_for_testing_member
      super.noSuchMethod(Invocation.getter(#compressionState),
          returnValue: HttpClientResponseCompressionState.notCompressed);

  @override
  int get contentLength =>
      // ignore: invalid_use_of_visible_for_testing_member
      super.noSuchMethod(Invocation.getter(#contentLength), returnValue: 0);

  @override
  int get statusCode =>
      // ignore: invalid_use_of_visible_for_testing_member
      super.noSuchMethod(Invocation.getter(#statusCode), returnValue: 0);

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      // ignore: invalid_use_of_visible_for_testing_member
      super.noSuchMethod(
          Invocation.method(#listen, [
            onData,
          ], {
            const Symbol("onError"): onError,
            const Symbol("onDone"): onDone,
            const Symbol("cancelOnError"): cancelOnError,
          }),
          returnValue: MockStreamSubscription<List<int>>());
}

class MockHttpHeaders extends Mock implements HttpHeaders {}

class MockStreamSubscription<T> extends Mock implements StreamSubscription<T> {}
