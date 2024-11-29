import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/components/reminder_list/sort_order_selector.dart';
import 'package:poke/components/reminder_list/sortable_fields.dart';
import 'package:poke/logger/poke_logger.dart';
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
  /// maps each action to a stream used to send messages to the list item.
  /// these streams are used to tell the list item to render a loading indicator
  /// while an action is updated, like when a new event is logged eg.
  ///
  /// Trigger loading state by sending `null` on this stream, and stop it by
  /// sending a reminder object.
  final Map<String /*action id*/, StreamController<Reminder?>>
      _listItemStreams = {};

  List<Reminder> _reminders = [];
  StreamSubscription? _reminderUpdateStreamSubscription;

  (SortableField<Reminder>, SortDirection) _sortOrder = (
    sortByDueDate,
    SortDirection.ascending,
  );

  @override
  void initState() {
    super.initState();

    _reminders = List.of(widget.reminderService.getReminders());
    _reminders.sort(compareReminders);

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
        setState(() {
          _reminders.add(update.reminder!);
          _reminders.sort(compareReminders);
        });
      }

      return;
    }

    if (update.type == UpdateType.removed) {
      setState(() {
        final wasRemoved = _reminders.remove(update.reminder!);
        _reminders.sort(compareReminders);

        if (!wasRemoved) {
          PokeLogger.instance().warn(
            'Tried to remove reminder that was not in list',
            data: {'reminder': update.reminder},
          );
        }
      });
    } else {
      listItemStream.add(update.reminder);
    }
  }

  @override
  Widget build(BuildContext context) {
    PokeLogger.instance().debug(
      'Building reminder list',
      data: {'reminders': _reminders},
    );

    Iterable<Widget> listItems = renderListItems(_reminders);

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        await widget.reminderService.syncWithPersistence();
        setState(() {});
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            SortOrderSelector(
              sortFields: [sortByLastEvent, sortByDueDate],
              initialSort: _sortOrder,
              onSort: (field, direction) {
                PokeLogger.instance().debug(
                  'Sorting reminders',
                  data: {'field': field, 'direction': direction},
                );

                setSort(field, direction);
              },
            ),
            PokeConstants.FixedSpacer(),
            ...listItems,
          ],
        ),
      ),
    );
  }

  Iterable<Widget> renderListItems(Iterable<Reminder> reminders) {
    // remove any existing list item controllers as we'll be creating new ones
    _listItemStreams.forEach((_, stream) => stream.close());
    _listItemStreams.clear();

    return _reminders.map((reminder) {
      final listItemStream = StreamController<Reminder?>();
      final actionId = reminder.action.equalityKey;

      _listItemStreams[actionId] = listItemStream;

      return Padding(
        padding: EdgeInsets.only(bottom: PokeConstants.space()),
        child: SizedBox(
          height: PokeConstants.space(15),
          child: StreamUpdatingWidget<Reminder>(
            key: ValueKey(actionId),
            initialData: reminder,
            dataStream: listItemStream.stream,
            buildChild: (context, data) => ReminderListItem(
              key: ValueKey(actionId),
              reminder: data,
              onTap: widget.onReminderTapped,
              swipeActions: widget.swipeActions,
            ),
          ),
        ),
      );
    });
  }

  // TODO: test
  void setSort(SortableField<Reminder> field, SortDirection direction) {
    setState(() {
      _sortOrder = (field, direction);
      _reminders.sort(compareReminders);
    });
  }

  int compareReminders(Reminder a, Reminder b) {
    final (field, direction) = _sortOrder;

    final fieldSort = field.compareAsc(a, b);
    final i = fieldSort == 0
        ? a.action.equalityKey.compareTo(b.action.equalityKey)
        : fieldSort;
    return i * (direction == SortDirection.ascending ? 1 : -1);
  }
}
