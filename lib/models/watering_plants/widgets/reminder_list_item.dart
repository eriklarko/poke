import 'package:flutter/widgets.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/design_system/poke_time_ago.dart';
import 'package:poke/models/reminder.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/models/watering_plants/widgets/plant_image.dart';

class PlantReminderListItem extends StatelessWidget {
  final Reminder reminder;

  const PlantReminderListItem({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final a = reminder.action as WaterPlantAction;

    final plant = a.plant;
    final lastEvent = a.getLastEvent();

    return Row(
      key: ValueKey('reminder-list-item-${reminder.action.equalityKey}'),
      children: [
        PlantImage.fill(plant.image),
        PokeConstants.FixedSpacer(2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PokeText(plant.name),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lastEvent != null)
                    PokeTimeAgo(
                      key: ValueKey('last-watered-${plant.id}'),
                      date: lastEvent.$1,
                      format: (timeAgo) => "Last watered $timeAgo",
                    ),
                  if (lastEvent?.$2!.addedFertilizer == true)
                    const PokeFinePrint('included fertilizer'),
                  if (reminder.dueDate != null)
                    PokeTimeAgo(
                      key: ValueKey('due-${plant.id}'),
                      date: reminder.dueDate!,
                      format: (timeAgo) => reminder.isDue()
                          ? "Due $timeAgo"
                          : "Will poke $timeAgo",
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
