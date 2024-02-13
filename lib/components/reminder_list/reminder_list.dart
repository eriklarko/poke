import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/persistence_event.dart';

import 'reminder_list_item.dart';

/// Renders a list of reminders :)
///
/// Subscribes to a Stream<PersistenceEvent> to rerender reminders when they
/// change.
class ReminderList extends StatefulWidget {
  final List<Reminder> reminders;
  final Stream<PersistenceEvent> updatesStream;
  final Function(Reminder) onTap;
  final Function(Reminder) onSnooze;

  const ReminderList({
    super.key,
    required this.reminders,
    required this.updatesStream,
    required this.onTap,
    required this.onSnooze,
  });

  @override
  State<ReminderList> createState() => _ReminderListState();
}

class _ReminderListState extends State<ReminderList> {
  final Map<String, PokeAsyncWidgetController> controllers = {};

  late StreamSubscription _subscription;

  @override
  void initState() {
    _subscription = widget.updatesStream.listen(_onEventReceived);
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _onEventReceived(PersistenceEvent event) {
    final PokeAsyncWidgetController? controller = controllers[event.key];
    if (controller == null) {
      PokeLogger.instance().warn(
        "No controller found",
        data: {
          "key": event.key,
        },
      );

      return;
    }

    if (event is Updating) {
      controller.setLoading();
    } else {
      controller.setIdle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.reminders.length,
      itemBuilder: (context, position) {
        final reminder = widget.reminders[position];

        final controller = PokeAsyncWidgetController();
        controllers[reminder.actionWithEvents.action.equalityKey] = controller;

        return UpdatingReminderListItem(
          controller: controller,
          reminder: reminder,
          onTap: widget.onTap,
          onSnooze: widget.onSnooze,
        );
      },
    );
  }
}
