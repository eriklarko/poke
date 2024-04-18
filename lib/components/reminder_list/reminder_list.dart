import 'dart:async';

import 'package:flutter/material.dart';
import 'package:poke/components/reminder_list/reminder_service.dart';
import 'package:poke/components/updating_widget/stream_updating_widget.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/async_widget/state.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_swipeable.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/reminder.dart';

import 'reminder_list_item.dart';

/// Renders a list of reminders :)
class ReminderList extends StatefulWidget {
  final ReminderService reminderService;
  final Function(Reminder) onReminderTapped;
  final List<SwipeAction<Reminder>>? swipeActions;

  const ReminderList({
    super.key,
    required this.reminderService,
    required this.onReminderTapped,
    this.swipeActions,
  });

  @override
  State<ReminderList> createState() => _ReminderListState();
}

class _ReminderListState extends State<ReminderList> {
  /// async controller used to show a loading indicator or error screen instead
  /// of the list of reminders
  final PokeAsyncWidgetController<String> _controller =
      PokeAsyncWidgetController();

  /// maps each action to the stream used to send messages to the list item.
  /// these streams are used to tell the list item to render a loading indicator
  /// while an action is updated, like when a new event is logged eg.
  ///
  /// Trigger loading state by sending `null` on this stream, and stop it by
  /// sending a reminder object.
  final Map<String /*action id*/, StreamController<Reminder?>>
      _listItemStreams = {};

  List<Reminder> _reminders = [];
  StreamSubscription? _reminderUpdateStreamSubscription;

  @override
  void initState() {
    super.initState();

    _loadReminders().then((_) {
      _reminderUpdateStreamSubscription =
          widget.reminderService.updatesStream().listen(_onUpdateReceived);
    });
  }

  @override
  void dispose() {
    super.dispose();

    _reminderUpdateStreamSubscription?.cancel();
  }

  Future<void> _loadReminders() async {
    _controller.setLoading();

    try {
      final newReminders = await widget.reminderService.buildReminders();
      newReminders.sort(compareReminders);

      if (!mounted) {
        // because of the await above we might have moved into a time where the
        // widget has been removed. This can happen if eg the app is reloaded
        // while we're fetching the reminders
        return;
      }

      setState(() {
        _reminders = newReminders;
      });

      _controller.setSuccessful();
    } catch (e) {
      PokeLogger.instance().error("Failed loading reminders", data: {
        "error": e,
        // TODO: Add something about which user and other context. Possibly on all errors??
      });

      if (mounted) {
        _controller.setErrored(e.toString());
      }
    }
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

  void _onUpdateReceived(ReminderUpdate update) async {
    if (!mounted) {
      return;
    }

    if (update.type == UpdateType.removed) {
      _removeReminder(update.actionId);
      return;
    }

    final listItemStream = _listItemStreams[update.actionId];
    if (listItemStream == null) {
      if (update.reminder != null) {
        // we didn't know about this reminder before, it must be new
        _addReminder(update.reminder!);
      }
      return;
    }

    // also update the reminder in memory in case the list builder is rerendered
    if (update.reminder != null) {
      // find the index in `_reminders` where the action is
      final i = _reminders.indexWhere((reminder) {
        return reminder.action.equalityKey ==
            update.reminder!.action.equalityKey;
      });
      // and replace the reminder
      _reminders[i] = update.reminder!;
    }

    listItemStream.add(update.reminder);
  }

  void _addReminder(Reminder reminder) {
    _reminders.add(reminder);
    setState(() {/* _reminders updated */});
  }

  void _removeReminder(String actionId) {
    _reminders.removeWhere(
      (reminder) => reminder.action.equalityKey == actionId,
    );
    setState(() {/* _reminders updated */});
  }

  @override
  Widget build(BuildContext context) {
    return PokeAsyncWidget(
      controller: _controller,
      builder: (context, state) {
        // remove any existing list item controllers as we'll be creating new ones
        _listItemStreams.forEach((_, stream) => stream.close());
        _listItemStreams.clear();

        return switch (state) {
          Loading() => const Center(child: PokeLoadingIndicator.large()),
          Error() => Column(
              children: [
                const PokeHeader("Failed loading reminders"),
                PokeText(state.error),
                PokeConstants.FixedSpacer(2),
                PokeButton.primary(
                  key: const ValueKey("retry"),
                  text: "retry",
                  onPressed: () {
                    _loadReminders();
                  },
                )
              ],
            ),
          Object() => ListView.builder(
              itemCount: _reminders.length,
              itemBuilder: (context, position) {
                final listItemStream = StreamController<Reminder?>();
                final reminder = _reminders[position];
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
            ),
        };
      },
    );
  }
}
