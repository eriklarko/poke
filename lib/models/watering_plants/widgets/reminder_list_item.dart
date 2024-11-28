import 'package:flutter/material.dart';
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
              PokeConstants.FixedSpacer(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lastEvent != null)
                      _renderIconAndText(
                        ValueKey('last-watered-${plant.id}'),
                        Icons.water_drop_outlined,
                        lastEvent.$1,
                      ),
                    Expanded(child: Container()),
                    if (reminder.dueDate != null)
                      Padding(
                        padding: EdgeInsets.only(right: PokeConstants.space(2)),
                        child: _renderIconAndText(
                          ValueKey('due-${plant.id}'),
                          Icons.alarm_outlined,
                          reminder.dueDate!,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _renderIconAndText(Key key, IconData icon, DateTime eventDate) {
    return Row(
      children: [
        Icon(icon, color: PokeConstants.colors.primary),
        PokeConstants.FixedSpacer(),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 75),
          child: PokeTimeAgo(
            key: key,
            date: eventDate,
            format: formatTimeAgo,
          ),
        ),
      ],
    );
  }

  // this is the most beautiful function I've ever written
  String formatTimeAgo(String timeAgo) {
    if (timeAgo.contains('from now')) {
      return "In ${timeAgo.replaceAll('from now', '')}";
    }
    return timeAgo;
  }
}
