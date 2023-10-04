import 'package:flutter/material.dart' hide Action;
import 'package:poke/models/action.dart';
import 'package:poke/utils/date_formatter.dart';

class WaterPlant implements Action {
  final Plant plant;
  final bool addedFertilizer;

  WaterPlant({required this.plant, required this.addedFertilizer});

  @override
  Widget buildReminderListItem(BuildContext context, {DateTime? lastEventAt}) {
    return Row(
      children: [
        Image.network('https://placekitten.com/40/40'),
        Column(
          children: [
            Text(plant.name),
            if (lastEventAt != null)
              Text('Last watered on ' + formatDate(lastEventAt)),
          ],
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}

class Plant {
  final String name;

  Plant({required this.name});
}
