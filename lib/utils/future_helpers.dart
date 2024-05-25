import 'dart:async';

Future<T> asFuture<T>(FutureOr<T> fOr) {
  if (fOr is Future<T>) {
    return fOr;
  }

  return Future.value(fOr);
}
