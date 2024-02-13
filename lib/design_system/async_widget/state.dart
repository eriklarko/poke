sealed class PokeAsyncWidgetState {
  static Idle idle = Idle();
  static Loading loading = Loading();
  static Success success = Success();

  static Error error<ErrorType>(ErrorType error) => Error<ErrorType>(error);

  bool isError() {
    return runtimeType == Error;
  }
}

final class Idle extends PokeAsyncWidgetState {}

final class Loading extends PokeAsyncWidgetState {}

final class Success extends PokeAsyncWidgetState {}

final class Error<ErrorType> extends PokeAsyncWidgetState {
  final ErrorType error;

  Error(this.error);
}
