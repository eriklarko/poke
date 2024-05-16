import 'package:flutter/material.dart' hide Action;
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/models/action.dart';
import 'package:poke/screens/action_details_screen/event_history.dart';

// TODO: Add delete functionality
class ActionDetailsScreen extends StatelessWidget {
  final Action action;
  final Widget body;

  const ActionDetailsScreen({
    super.key,
    required this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Show if notification is scheduled
    return Scaffold(
        appBar: PokeAppBar(context),
        body: Column(
          children: [
            body,
            Expanded(
              child: EventHistory(action: action),
            ),
          ],
        ));
  }
}
