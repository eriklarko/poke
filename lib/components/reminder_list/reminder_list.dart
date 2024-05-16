import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/reminder_service/reminder_service.dart';
import 'package:poke/components/updating_widget/stream_updating_widget.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_swipeable.dart';
import 'package:poke/models/reminder.dart';

import 'reminder_list_item.dart';

/// Renders a list of reminders :)
class ReminderList extends StatefulWidget {
  final ReminderService reminderService = GetIt.instance.get<ReminderService>();
  final Function(Reminder) onReminderTapped;
  final List<SwipeAction<Reminder>>? swipeActions;

  ReminderList({
    super.key,
    required this.onReminderTapped,
    this.swipeActions,
  });

  @override
  State<ReminderList> createState() => _ReminderListState();
}

class _ReminderListState extends State<ReminderList> {
  /// maps each action to the stream used to send messages to the list item.
  /// these streams are used to tell the list item to render a loading indicator
  /// while an action is updated, like when a new event is logged eg.
  ///
  /// Trigger loading state by sending `null` on this stream, and stop it by
  /// sending a reminder object.
  final Map<String /*action id*/, StreamController<Reminder?>>
      _listItemStreams = {};

  StreamSubscription? _reminderUpdateStreamSubscription;

  @override
  void initState() {
    super.initState();

    _reminderUpdateStreamSubscription =
        widget.reminderService.updatesStream().listen(_onUpdateReceived);
  }

  @override
  void dispose() {
    super.dispose();

    _reminderUpdateStreamSubscription?.cancel();
  }

  void _onUpdateReceived(ReminderUpdate update) async {
    if (!mounted) {
      return;
    }

    final listItemStream = _listItemStreams[update.actionId];
    if (listItemStream == null) {
      if (update.type == UpdateType.updated ||
          update.type == UpdateType.added) {
        // this action hasn't been seen before, time to trigger a rerender
        setState(() {/* reminders has changed */});
      }
    } else {
      listItemStream.add(update.reminder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = List.of(widget.reminderService.getReminders());
    reminders.sort(compareReminders);

    // remove any existing list item controllers as we'll be creating new ones
    _listItemStreams.forEach((_, stream) => stream.close());
    _listItemStreams.clear();

    return ListView.builder(
      itemCount: reminders.length,
      itemBuilder: (context, position) {
        final listItemStream = StreamController<Reminder?>();
        final reminder = reminders[position];
        final actionId = reminder.action.equalityKey;

        _listItemStreams[actionId] = listItemStream;

        return Padding(
          padding: EdgeInsets.only(bottom: PokeConstants.space()),
          child: SizedBox(
            height: PokeConstants.space(15),
            child: StreamUpdatingWidget<Reminder>(
              initialData: reminder,
              dataStream: listItemStream.stream,
              buildChild: (context, data) => ReminderListItem(
                reminder: data,
                onTap: widget.onReminderTapped,
                swipeActions: widget.swipeActions,
              ),
            ),
          ),
        );
      },
    );
  }

  int compareReminders(Reminder a, Reminder b) {
    if (a.dueDate == null) {
      if (b.dueDate == null) {
        // if both dates are null, sort according to some other reasonable prop
        return a.action.equalityKey.compareTo(b.action.equalityKey);
      }

      // if `a` has no due date, but `b` does; show `b` first
      return 1;
    }

    if (b.dueDate == null) {
      // here we know that `a` has a due date, but `b` doesn't. Show `a` first
      return -1;
    }

    // both reminders have due dates, show the oldest due date first
    return a.dueDate!.compareTo(b.dueDate!);
  }
}
