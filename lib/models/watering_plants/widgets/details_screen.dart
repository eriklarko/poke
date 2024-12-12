import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/design_system/poke_time_ago.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/models/watering_plants/widgets/plant_image.dart';
import 'package:poke/reminder_service/reminder_service.dart';
import 'package:poke/screens/action_details_screen/event_history.dart';
import 'package:poke/services/delete_action.dart';

class DetailsScreen extends StatelessWidget {
  final reminderService = GetIt.instance.get<ReminderService>();

  final WaterPlantAction action;

  DetailsScreen({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final lastEvent = action.getLastEvent();
    final reminder = reminderService.buildReminder(action);

    // TODO: make delete button nice

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(PokeConstants.space()),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TODO: make editable
                      PokeText(action.plant.name),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lastEvent != null)
                            PokeTimeAgo(
                              key: ValueKey('last-watered-${action.plant.id}'),
                              date: lastEvent.$1,
                              format: (timeAgo) => "Last watered $timeAgo",
                            ),
                          if (lastEvent?.$2!.addedFertilizer == true)
                            const PokeFinePrint('included fertilizer'),
                          if (reminder.dueDate != null)
                            PokeTimeAgo(
                              key: ValueKey('due-${action.plant.id}'),
                              date: reminder.dueDate!,
                              format: (timeAgo) => reminder.isDue()
                                  ? "Due $timeAgo"
                                  : "Will poke $timeAgo",
                            ),
                          PokeConstants.fixedSpacer(2),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  // TODO: make editable
                  child: PlantImage.fill(action.plant.image),
                ),
              ],
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
          PokeButton.primaryDangerous(
            text: "Delete",
            onPressed: () => deleteAction(context, action),
          )
        ],
      ),
    );
  }
}
