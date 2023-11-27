import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_async_button.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/persistence/persistence.dart';

class NewInstanceWidget extends StatefulWidget {
  final Persistence persistence;
  const NewInstanceWidget({super.key, required this.persistence});

  @override
  State<NewInstanceWidget> createState() => _NewInstanceWidgetState();
}

class _NewInstanceWidgetState extends State<NewInstanceWidget> {
  final plantNameController = TextEditingController();

  @override
  void dispose() {
    plantNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
      mainAxisAlignment: MainAxisAlignment.start, // move to top
      children: [
        Image.asset('assets/cat.jpeg'),
        Row(
          children: [
            const Column(
              children: [
                PokeText('Plant'),
              ],
            ),
            PokeConstants.FixedSpacer(),
            Flexible(
              child: Column(
                children: [
                  TextField(
                    controller: plantNameController,
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: PokeConstants.space()),
          child: PokeAsyncButton.once(
            text: 'Create',
            onPressed: () {
              return widget.persistence.createAction(
                WaterPlantAction(
                  plant: Plant(
                    id: plantNameController.text.hashCode.toString(), // lul
                    name: plantNameController.text,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
