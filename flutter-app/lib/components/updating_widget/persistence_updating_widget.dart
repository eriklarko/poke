import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/persistence_event.dart';

import 'updating_widget.dart';

// PersistenceUpdatingWidget can be used to automatically rerender a widget when
// a `PersistenceEvent` for an action is received.
//
// The `map` property can be used to derive the data to show from the
// PersitenceEvent. This is useful if showing something like an action name that
// the user can change, in which case it'd look a bit like this
//    map: (event) {
//      if (event is Updated) {
//        return await persistence.getAction(event.actionId).name;
//      }
//      return null;
//    }
//
// Example:
//   // the action whose persistence events will trigger the rerender
//   final action = SomeAction();
//   PersistenceUpdatingWidget<void>(
//     actionId: action.equalityKey,
//     initialData: null,
//     buildChild: (context, _) => FutureBuilder<Action>(
//       future: persistence.getAction(action.equalityKey),
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           return Text(snapshot.data.toString());
//         }
//         return PokeLoadingIndicator.small();
//       },
//     ),
//   );
class PersistenceUpdatingWidget<T> extends StatefulWidget {
  final String actionId;
  final T initialData;
  final FutureOr<T> Function(PersistenceEvent)? map;
  final Widget Function(BuildContext, T) buildChild;

  const PersistenceUpdatingWidget({
    super.key,
    required this.actionId,
    required this.initialData,
    this.map,
    required this.buildChild,
  });

  @override
  State<PersistenceUpdatingWidget<T>> createState() =>
      _PersistenceUpdatingWidgetState<T>();
}

class _PersistenceUpdatingWidgetState<T>
    extends State<PersistenceUpdatingWidget<T>> {
  final _controller = UpdatingWidgetController();
  StreamSubscription<PersistenceEvent>? _streamSubscription;
  late T _lastKnownData;

  @override
  void initState() {
    super.initState();

    _lastKnownData = widget.initialData;

    _streamSubscription =
        GetIt.instance.get<Persistence>().getNotificationStream().listen(
      (event) async {
        if (event.actionId != widget.actionId) {
          return;
        }

        if (event is Updating) {
          _controller.setLoading();
        } else {
          if (widget.map != null) {
            _lastKnownData = await widget.map!(event);
          }
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
