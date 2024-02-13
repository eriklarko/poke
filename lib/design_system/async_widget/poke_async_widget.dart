import 'package:flutter/material.dart';

import 'state.dart';

// PokeAsyncWidget is used for buttons and such that trigger asynchronous
// actions. The widget shown to the user can be changed to a loading state while
// the asynchronous action is being executed, after which either a success or
// error widget is shown.
//
// Example:
//  class SomeWidget extends StatelessWidget {
//    SomeWidget({super.key});
//
//    // create the controller used to set the PokeAsyncWidget state
//    final _controller = PokeAsyncWidgetController();
//
//    @override
//    Widget build(BuildContext context) {
//      return PokeAsyncWidget(
//          // pass in the controller created outside of the build function
//          controller: _controller,
//          builder: (BuildContext context, PokeAsyncWidgetState state) {
//            return switch (state) {
//              Idle() => ElevatedButton(
//                  child: const Text('act'),
//                  onPressed: () {
//                    // tell PokeAsyncWidget to start showing the loading state
//                    _controller.setLoading();
//
//                    // trigger the asynchronous action
//                    Future.delayed(const Duration(seconds: 2)).then((_) {
//                      // tell PokeAsyncWidget that the asynchronous action completed successfully
//                      _controller.setSuccessful();
//
//                      // if the action failed, use _controller.setErrored('reason');
//                    });
//                  },
//                ),
//              Loading() => const Text("loading..."),
//              Success() => const Text("Async task completed!"),
//              Error() => Text("Error ${state.error}"),
//            };
//          });
//    }
//  }
class PokeAsyncWidget<ErrorType> extends StatefulWidget {
  final PokeAsyncWidgetController<ErrorType> controller;

  final Widget Function(BuildContext, PokeAsyncWidgetState) builder;

  const PokeAsyncWidget({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  State<PokeAsyncWidget<ErrorType>> createState() => _WidgetState();

  // This factory constructor simplifies the usage of the async widget slightly by
  // allowing you to pass widgets for each state instead of implementing the
  // builder function yourself
  // Example:
  //  class SomeWidget extends StatelessWidget {
  //    SomeWidget({super.key});
  //
  //    // create the controller used to set the PokeAsyncWidget state
  //    final _controller = PokeAsyncWidgetController();
  //
  //    @override
  //    Widget build(BuildContext context) {
  //      return PokeAsyncWidget.simple(
  //        // pass in the controller created outside of the build function
  //        controller: _controller,
  //
  //        // specify the "idle" state, this is what is shown to the user before the
  //        // asynchronous action has been triggered
  //        idle: ElevatedButton(
  //          child: const Text('act'),
  //          onPressed: () {
  //            // tell PokeAsyncWidget to start showing the loading state
  //            _controller.setLoading();
  //
  //            // trigger the asynchronous action
  //            Future.delayed(const Duration(seconds: 2)).then((_) {
  //              // tell PokeAsyncWidget that the asynchronous action completed successfully
  //              _controller.setSuccessful();
  //
  //              // if the action failed, use _controller.setErrored('reason');
  //            });
  //          },
  //        ),
  //
  //        // specify the "loading" state, this is what is shown to the user while
  //        // the asynchronous action is running
  //        loading: const Text('loading...'),
  //
  //        // specify the "success" state, this is what is shown to the user if the
  //        // asynchronous action completed successfully.
  //        //
  //        // omit this property if you want the button to show the idle state
  //        // again instead
  //        success: const Text('done!'),
  //
  //        // specify the "error" state, this is what is shown to the user if the
  //        // asynchronous action failed. A reason for the failure can be passed into
  //        // `_controller.setErrored`. The error type can be set when creating the
  //        // controller like this
  //        //    final _controller = PokeAsyncWidgetController<String>();
  //        error: (error) => Text(error.toString()),
  //      );
  //    }
  //  }
  PokeAsyncWidget.simple({
    Key? key,
    required PokeAsyncWidgetController<ErrorType> controller,
    required Widget idle,
    required Widget loading,
    Widget? success,
    required Widget Function(ErrorType error) error,
  }) : this(
          key: key,
          controller: controller,
          builder: (context, state) {
            return switch (state) {
              Idle() => idle,
              Loading() => loading,
              Success() => success ?? idle,
              Error() => error(state.error),
            };
          },
        );
}

class _WidgetState<ErrorType> extends State<PokeAsyncWidget<ErrorType>> {
  PokeAsyncWidgetState _state = PokeAsyncWidgetState.idle;

  @override
  void initState() {
    super.initState();
    widget.controller._setState(this);
  }

  setLoading() {
    setState(() {
      _state = PokeAsyncWidgetState.loading;
    });
  }

  setSuccessful() {
    setState(() {
      _state = PokeAsyncWidgetState.success;
    });
  }

  setErrored(ErrorType error) {
    setState(() {
      _state = PokeAsyncWidgetState.error(error);
    });
  }

  // could also be called reset
  setIdle() {
    setState(() {
      _state = PokeAsyncWidgetState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _state);
  }
}

class PokeAsyncWidgetController<ErrorType> {
  _WidgetState? _state;

  _setState(_WidgetState state) {
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

  setIdle() {
    _state!.setIdle();
  }
}
