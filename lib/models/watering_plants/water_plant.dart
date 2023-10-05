import 'package:flutter/material.dart' hide Action;
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_checkbox.dart';
import 'package:poke/models/action.dart';
import 'package:poke/utils/date_formatter.dart';

class WaterPlant implements Action {
  final Plant plant;
  final bool addedFertilizer;
  final DateTime? lastEventAt;

  WaterPlant(
      {required this.plant, required this.addedFertilizer, this.lastEventAt});

  @override
  Widget buildReminderListItem(BuildContext context) {
    return Row(
      children: [
        plant.image,
        Column(
          children: [
            Text(plant.name),
            if (lastEventAt != null)
              Text('Last watered on ${formatDate(lastEventAt!)}'),
          ],
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }

  @override
  buildAddEventWidget(BuildContext context) {
    final fertilizerCheckbox = PokeCheckbox();
    return Column(
      children: [
        plant.image,
        Text(plant.name),
        if (lastEventAt != null)
          Text('Last watered on ${formatDate(lastEventAt!)}'),
        Row(
          children: [
            Text('Added fertilizer'),
            fertilizerCheckbox,
          ],
        ),
        PokeButton(
          onPressed: () {
            print('pressed btnn ${fertilizerCheckbox.isChecked}');
          },
          child: Text('Watered!'),
        ),
      ],
    );
  }
}

final defaultImage = Image.network('https://placekitten.com/40/40');

class Plant {
  final String name;
  late final Image? _image;

  Plant({required this.name, image}) {
    _image = image;
  }

  Image get image {
    return _image ?? defaultImage;
  }
}
