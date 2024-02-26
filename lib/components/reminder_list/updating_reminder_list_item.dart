import 'package:flutter/material.dart' hide Overlay;
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_swipeable.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/reminder.dart';

import 'overlay.dart';
import 'reminder_list_item.dart';

// Wraps a `ReminderListItem`, providing a means to render a loading indicator
// on top of it while the reminder data is being updated.
class UpdatingReminderListItem extends StatefulWidget {
  final Reminder initialData;
  // TODO: document that sending null on this stream shows the loading indicator
  final Stream<Reminder?> dataStream;
  final Function(Reminder) onTap;
  final List<SwipeAction<Reminder>>? swipeActions;

  const UpdatingReminderListItem({
    super.key,
    required this.initialData,
    required this.dataStream,
    required this.onTap,
    this.swipeActions,
  });

  @override
  State<UpdatingReminderListItem> createState() =>
      _UpdatingReminderListItemState();
}

class _UpdatingReminderListItemState extends State<UpdatingReminderListItem> {
  // TODO: describe; used to render something behind the loading indicator while new data is coming in
  late Reminder _lastKnownReminder;

  @override
  void initState() {
    super.initState();
    _lastKnownReminder = widget.initialData;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Reminder?>(
      stream: widget.dataStream,
      initialData: widget.initialData,
      builder: buildListItem,
    );
  }

  Widget buildListItem(
    BuildContext context,
    AsyncSnapshot<Reminder?> snapshot,
  ) {
    final Widget listItem = ReminderListItem(
      reminder: snapshot.data ?? _lastKnownReminder,
      onTap: widget.onTap,
      swipeActions: widget.swipeActions,
    );

    // if we have data, return just the list item; no loading overlay or anything required
    // `snapshot.hasData` is false if `null` was sent on the stream.
    if (snapshot.hasData) {
      return listItem;
    }

    if (snapshot.hasError) {
      return Stack(children: [
        listItem,
        Overlay(
          child: PokeText("NOO $snapshot.error"),
        ),
      ]);
    }

    // we don't have any data or any errors, we must be loading
    return Stack(children: [
      listItem,
      const Overlay(
        child: PokeLoadingIndicator.small(color: Colors.white),
      ),
    ]);
  }
}
