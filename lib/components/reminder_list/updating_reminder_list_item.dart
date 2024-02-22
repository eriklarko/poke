import 'dart:async';

import 'package:flutter/material.dart' hide Overlay;
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/async_widget/poke_async_widget.dart';
import 'package:poke/design_system/async_widget/state.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/persistence_event.dart';
import 'package:poke/persistence/reminder_builder.dart';
import 'package:poke/predictor/predictor.dart';

import 'overlay.dart';
import 'reminder_list_item.dart';

class UpdatingReminderListItem extends StatefulWidget {
  final Reminder reminder;
  final Function(Reminder) onTap;
  final Function(Reminder) onSnooze;

  const UpdatingReminderListItem({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onSnooze,
  });

  @override
  State<UpdatingReminderListItem> createState() =>
      _UpdatingReminderListItemState();
}

class _UpdatingReminderListItemState extends State<UpdatingReminderListItem> {
  final Persistence persistence = GetIt.instance.get<Persistence>();
  final Predictor predictor = GetIt.instance.get<Predictor>();
  final PokeAsyncWidgetController _controller = PokeAsyncWidgetController();

  Reminder? updatedReminder;

  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    _subscription =
        persistence.getNotificationStream().listen(_onEventReceived);
  }

  @override
  void dispose() {
    super.dispose();

    _subscription.cancel();
  }

  void _onEventReceived(PersistenceEvent event) async {
    if (event is Updating) {
      _controller.setLoading();
    } else {
      final updatedAction = await persistence
          .getAction(widget.reminder.actionWithEvents.action.equalityKey);

      final Reminder reminder = buildReminder(updatedAction, predictor);
      setState(() {
        updatedReminder = reminder;
      });

      _controller.setIdle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PokeAsyncWidget(
      controller: _controller,
      builder: (context, state) {
        final Widget listItem = ReminderListItem(
          updatedReminder ?? widget.reminder,
          onTap: widget.onTap,
          onSnooze: widget.onSnooze,
        );

        return switch (state) {
          Loading() => Stack(children: [
              listItem,
              const Overlay(
                child: PokeLoadingIndicator.small(color: Colors.white),
              ),
            ]),
          Error() => Stack(children: [
              listItem,
              Overlay(
                child: PokeText("NOO $state.error"),
              ),
            ]),
          Object() => listItem,
        };
      },
    );
  }
}
