import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

typedef SwipeAction<T> = (Function(T), Widget);

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
                  onPressed: (_) => swipeAction.$1(value),
                  child: SizedBox.expand(child: swipeAction.$2),
                ))
            .toList(),
      ),
      child: child,
    );
  }
}
