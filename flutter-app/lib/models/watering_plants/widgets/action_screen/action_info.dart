import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/design_system/poke_time_ago.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/models/watering_plants/widgets/action_screen/editable_text_field.dart';
import 'package:poke/models/watering_plants/widgets/plant_image.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/reminder_service/reminder_service.dart';

class ActionInfo extends StatelessWidget {
  final WaterPlantAction action;
  final reminderService = GetIt.instance.get<ReminderService>();
  final persistence = GetIt.instance.get<Persistence>();

  ActionInfo(this.action, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EditableTextField(
                action.plant.name,
                iconSize: 15,
                onChanged: (newName) async {
                  // dump copy of action to json and change the plant name
                  final j = action.toJson();
                  j['plant']['name'] = newName;
                  final a2 = Action.fromJson(j) as WaterPlantAction;

                  await persistence.updateAction(action.equalityKey, a2);
                },
              ),
              _buildEventDetails(),
            ],
          ),
        ),
        SizedBox(
          width: 100,
          // TODO: make editable
          child: PlantImage.fill(action.plant.image),
        ),
      ],
    );
  }

  Widget _buildEventDetails() {
    final lastEvent = action.getLastEvent();
    final reminder = reminderService.buildReminder(action);

    return Column(
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
            format: (timeAgo) =>
                reminder.isDue() ? "Due $timeAgo" : "Will poke $timeAgo",
          ),
        PokeConstants.fixedSpacer(2),
      ],
    );
  }
}
