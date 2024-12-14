import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';

// This is any widget that you want to drag to the side to display a set of
// options related to that widget. The by far most common example is items in
// lists where you can drag to star or remove eg
class PokeSwipeable<T> extends StatelessWidget {
  // The thing being swiped
  final Widget child;

  /// what gets passed into the swipe action callback functions
  final T value;

  final List<SwipeAction<T>> swipeActions;

  const PokeSwipeable({
    required Key key,
    required this.child,
    required this.swipeActions,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: swipeActions
            .map((swipeAction) => CustomSlidableAction(
                  flex: 1,
                  onPressed: (_) => swipeAction.act(value),
                  child: SizedBox.expand(child: swipeAction.widget),
                ))
            .toList(),
      ),
      child: child,
    );
  }
}

class SwipeAction<T> {
  final void Function(T) act;
  final Widget widget;

  const SwipeAction({
    required this.act,
    required this.widget,
  });

  factory SwipeAction.async({
    required Future<void> Function(T) act,
    required Widget widget,
    Widget Function(Widget)? wrapAsyncWidget,
  }) {
    final asyncController = PokeAsyncWidgetController<Exception>();
    final asyncWidget = PokeAsyncWidget.simple(
      controller: asyncController,
      idle: widget,
      loading: PokeLoadingIndicator.small(),
      error: (_) => const Icon(Icons.error),
    );

    return SwipeAction<T>(
      act: (value) {
        final future = act(value);
        asyncController.listenToFuture(future);
      },
      widget: wrapAsyncWidget?.call(asyncWidget) ?? asyncWidget,
    );
  }
}
