import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_async_button.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/plant_image.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/persistence/persistence.dart';

class NewInstanceWidget extends StatefulWidget {
  final Persistence persistence;
  const NewInstanceWidget({super.key, required this.persistence});

  @override
  State<NewInstanceWidget> createState() => NewInstanceWidgetState();
}

// this state is not private because I need to access the `uploadImage` function
// in a test
class NewInstanceWidgetState extends State<NewInstanceWidget> {
  final plantNameController = TextEditingController();
  bool _createButtonEnabled = true;
  Uri? _imageUri;

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
      mainAxisSize: MainAxisSize.min,
      children: [
        PlantImage.large(
          onNewImage: uploadImage,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PokeText('Plant'),
            PokeConstants.FixedSpacer(),
            Container(
              // TextFields do not like being in rows because they get infinite width.
              // so the size must be limited here
              constraints: const BoxConstraints(maxWidth: 150),
              child: TextField(
                key: const ValueKey('plant-name'),
                controller: plantNameController,
              ),
            ),
          ],
        ),
        PokeConstants.FixedSpacer(3),
        PokeAsyncButton.once(
          text: 'Create',
          onPressed: _createButtonEnabled
              ? () {
                  return widget.persistence.createAction(
                    WaterPlantAction(
                      plant: Plant(
                        id: plantNameController.text.hashCode.toString(), // lul
                        name: plantNameController.text,
                        imageUri: _imageUri,
                      ),
                    ),
                  );
                }
              : null,
        ),
      ],
    );
  }

  Future<void> uploadImage(bytes) async {
    // disable create button
    setState(() {
      _createButtonEnabled = false;
    });

    try {
      // upload image
      // store uri for later
      _imageUri = await widget.persistence.uploadData(
        bytes,
        newPlantImageStorageKey(),
      );

      // TODO: What to do when upload fails?
    } finally {
      // enable create button
      setState(() {
        _createButtonEnabled = true;
      });
    }
  }
}
