// An action in this app means that the user did something they want to be poked
// about in the future, like watering a plant or replacing an AC filter

import 'package:flutter/material.dart';

abstract interface class Action {
  Widget buildReminderListItem(BuildContext context, {DateTime? lastEventAt});
}

class ReplacedACFilter extends Action {
  @override
  Widget buildReminderListItem(BuildContext context, {DateTime? lastEventAt}) {
    // TODO: implement buildReminderListItem
    throw UnimplementedError();
  }
}
