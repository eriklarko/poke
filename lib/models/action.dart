// An action in this app is something the user wants to be poked about in the
// future, like watering a plant or replacing an AC filter.

import 'package:flutter/material.dart';
import 'package:poke/event_storage/event_storage.dart';

abstract class Action {
  DateTime? lastEvent;

  Action({this.lastEvent});

  // Creates the UI used to show this action in the reminder list
  Widget buildReminderListItem(BuildContext context);

  // Creates the UI to use when executing this action, or adding an event of
  // this action. An event in Poke is when an action was performed.
  Widget buildLogActionWidget(BuildContext context, EventStorage eventStorage);
}

class ReplaceACFilter extends Action {
  @override
  Widget buildReminderListItem(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  Widget buildLogActionWidget(BuildContext context, EventStorage eventStorage) {
    throw UnimplementedError();
  }
}
