import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/screens/action_details_screen/event_history.dart';

class ActionDetailsScreen extends StatelessWidget {
  final ActionWithEvents actionWithEvents;
  final Widget body;

  const ActionDetailsScreen(
      {super.key, required this.body, required this.actionWithEvents});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PokeAppBar(context),
        body: Column(
          children: [
            body,
            Expanded(
              child: EventHistory(actionWithEvents: actionWithEvents),
            ),
          ],
        ));
  }
}
