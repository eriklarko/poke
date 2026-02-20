import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/models/watering_plants/widgets/action_screen/action_info.dart';
import 'package:poke/models/watering_plants/widgets/action_screen/log_action_widget.dart';
import 'package:poke/screens/action_screen/event_history.dart';
import 'package:poke/services/delete_action.dart';

class ActionScreen extends StatelessWidget {
  final WaterPlantAction action;

  const ActionScreen({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    // TODO: make delete button nice
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(PokeConstants.space()),
            child: ActionInfo(action),
          ),
          PokeConstants.fixedSpacer(1),
          Padding(
            padding: EdgeInsets.all(PokeConstants.space()),
            child: Align(
              alignment: Alignment.centerRight,
              child: IntrinsicWidth(child: LogActionWidget(action)),
            ),
          ),
          PokeConstants.fixedSpacer(2),
          Padding(
            padding: EdgeInsets.only(left: PokeConstants.space()),
            child: PokeText("Event History:"),
          ),
          PokeConstants.fixedSpacer(),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 1000,
            ),
            child: EventHistory(action: action),
          ),
          PokeConstants.fixedSpacer(),
          Center(
            child: PokeButton.primaryDangerous(
              text: "Delete",
              onPressed: () => deleteAction(context, action),
            ),
          )
        ],
      ),
    );
  }
}
