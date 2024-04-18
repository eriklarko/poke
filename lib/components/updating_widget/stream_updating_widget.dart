import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:poke/components/updating_widget/updating_widget.dart';

class StreamUpdatingWidget<T> extends StatefulWidget {
  final T initialData;
  final Stream<T?> dataStream;
  final Widget Function(BuildContext, T data) buildChild;

  const StreamUpdatingWidget({
    super.key,
    required this.initialData,
    required this.dataStream,
    required this.buildChild,
  });

  @override
  State<StreamUpdatingWidget<T>> createState() =>
      _StreamUpdatingWidgetState<T>();
}

class _StreamUpdatingWidgetState<T> extends State<StreamUpdatingWidget<T>> {
  final _controller = UpdatingWidgetController();
  StreamSubscription<T?>? _streamSubscription;
  late T _lastKnownData;

  @override
  void initState() {
    super.initState();
    _lastKnownData = widget.initialData;

    _streamSubscription = widget.dataStream.listen(
      (event) {
        if (event == null) {
          _controller.setLoading();
        } else {
          _lastKnownData = event;
          _controller.setDone();
        }
      },
      onError: (error) {
        _controller.setError(error.toString());
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    _streamSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return UpdatingWidget(
      controller: _controller,
      buildChild: (context) => widget.buildChild(context, _lastKnownData),
    );
  }
}
