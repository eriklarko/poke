import 'package:flutter/material.dart';

// PokeAsyncWidget is used for buttons and such that trigger asynchronous
// actions. The widget shown to the user can be changed to a loading state while
// the asynchronous action is being executed, after which either a success or
// error widget is shown.
//
// Example:
//   class SomeWidget extends StatelessWidget {
//     SomeWidget({super.key});
//
//     // create the controller used to set the PokeAsyncWidget state
//     final _controller = PokeAsyncWidgetController();
//
//     @override
//     Widget build(BuildContext context) {
//       return PokeAsyncWidget(
//         // pass in the controller created outside of the build function
//         controller: _controller,
//
//         // specify the "idle" state, this is what is shown to the user before the
//         // asynchronous action has been triggered
//         idle: ElevatedButton(
//           child: const Text('act'),
//           onPressed: () {
//             // tell PokeAsyncWidget to start showing the loading state
//             _controller.setLoading();
//
//             // trigger the asynchronous action
//             Future.delayed(const Duration(seconds: 2)).then((_) {
//               // tell PokeAsyncWidget that the asynchronous action completed successfully
//               _controller.setSuccessful();
//
//               // if the action failed, use _controller.setErrored('reason');
//             });
//           },
//         ),
//
//         // specify the "loading" state, this is what is shown to the user while
//         // the asynchronous action is running
//         loading: const Text('loading...'),
//
//         // specify the "success" state, this is what is shown to the user if the
//         // asynchronous action completed successfully.
//         //
//         // omit this property if you want the button to show the idle state
//         // again instead
//         success: const Text('done!'),
//
//         // specify the "error" state, this is what is shown to the user if the
//         // asynchronous action failed. A reason for the failure can be passed into
//         // `_controller.setErrored`. The error type can be set when creating the
//         // controller like this
//         //    final _controller = PokeAsyncWidgetController<String>();
//         error: (Object error) => Text(error.toString()),
//       );
//     }
//   }
class PokeAsyncWidget<ErrorType> extends StatefulWidget {
  final Widget idle;
  final Widget loading;
  final Widget? success;
  final Widget Function(ErrorType error) error;
  final PokeAsyncWidgetController<ErrorType> controller;

  const PokeAsyncWidget({
    super.key,
    required this.idle,
    required this.loading,
    this.success,
    required this.error,
    required this.controller,
  });

  @override
  State<PokeAsyncWidget<ErrorType>> createState() => _PokeAsyncWidgetState();
}

class PokeAsyncWidgetController<ErrorType> {
  _PokeAsyncWidgetState<ErrorType>? _state;

  _setState(_PokeAsyncWidgetState<ErrorType> state) {
    _state = state;
  }

  setLoading() {
    _state!.setLoading();
  }

  setSuccessful() {
    _state!.setSuccessful();
  }

  setErrored(ErrorType error) {
    _state!.setErrored(error);
  }
}

enum _State {
  idle,
  loading,
  success,
  error,
}

class _PokeAsyncWidgetState<ErrorType>
    extends State<PokeAsyncWidget<ErrorType>> {
  _State _state = _State.idle;
  ErrorType? _error = null;

  @override
  void initState() {
    super.initState();
    widget.controller._setState(this);
  }

  setLoading() {
    setState(() {
      _state = _State.loading;
    });
  }

  setSuccessful() {
    setState(() {
      _state = _State.success;
    });
  }

  setErrored(ErrorType error) {
    setState(() {
      _state = _State.error;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _State.idle => widget.idle,
      _State.loading => widget.loading,
      _State.success => widget.success ?? widget.idle,
      _State.error => widget.error(_error!),
    };
  }
}
