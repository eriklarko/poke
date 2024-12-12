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
    return Row(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 250),
          child: PlantImage.fill(plant.image),
        ),
        PokeConstants.fixedSpacer(2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PokeText(plant.name),
              PokeConstants.fixedSpacer(),
              _renderActionData(a),
              Expanded(child: Container()), // just take up the remaining space
            ],
          ),
        ),
      ],
    );
  }

  Widget _renderActionData(WaterPlantAction a) {
    final lastEvent = a.getLastEvent();

    return Row(
      //crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lastEvent != null)
          _renderIconAndText(
            ValueKey('last-watered-${a.plant.id}'),
            Icons.water_drop_outlined,
            lastEvent.$1,
          ),
        Expanded(child: Container()),
        if (reminder.dueDate != null)
          Padding(
            padding: EdgeInsets.only(right: PokeConstants.space()),
            child: _renderIconAndText(
              ValueKey('due-${a.plant.id}'),
              Icons.alarm_outlined,
              reminder.dueDate!,
              color: reminder.isDue() ? PokeConstants.colors.error : null,
            ),
          ),
      ],
    );
  }

  Widget _renderIconAndText(Key key, IconData icon, DateTime eventDate,
      {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? PokeConstants.colors.primary),
        PokeConstants.fixedSpacer(),
        SizedBox(
          width: 75,
          child: Container(
            alignment: Alignment.centerLeft,
            child: PokeTimeAgo(
              key: key,
              date: eventDate,
              format: formatTimeAgo,
            ),
          ),
        ),
      ],
    );
  }

  // this is the most beautiful function I've ever written
  // actually, it's a method.
  // trurd. true turd. beat that, future me
  String formatTimeAgo(String timeAgo) {
    if (timeAgo.contains('from now')) {
      return "In ${timeAgo.replaceAll('from now', '')}";
    }
    return timeAgo;
  }
}
