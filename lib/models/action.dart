// An action in this app means that the user did something they want to be poked
// about in the future, like watering a plant or replacing an AC filter

import 'package:flutter/material.dart';

abstract interface class Action {
  // Creates the UI used to show this action in the reminder list
  Widget buildReminderListItem(BuildContext context);
}

class ReplaceACFilter extends Action {
  @override
  Widget buildReminderListItem(BuildContext context) {
    throw UnimplementedError();
  }

  @override
    throw UnimplementedError();
  }
}
