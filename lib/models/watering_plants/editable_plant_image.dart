import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/persistence/persistence.dart';

import 'plant_image.dart';
import 'water_plant.dart';

// Shows the image associated with a WaterPlanAction's plant, and allows
// the user to tap the image to change it.
class EditablePlantImage extends StatelessWidget {
  final WaterPlantAction action;

  const EditablePlantImage({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return PlantImage.large(
      image: action.plant.image,
      onNewImage: updateImage,
    );
  }

  Future<void> updateImage(Uint8List imgBytes) async {
    final persistence = GetIt.instance.get<Persistence>();

    // upload the image to persistent storage
    final uri = await persistence.uploadData(
      imgBytes,
      newPlantImageStorageKey(actionId: action.equalityKey),
    );
    // TODO: What to do when upload fails? TEST ON DEVICE!

    // update plant object in the persistent storage to use the newly uploaded image
    action.plant.imageUri = uri;
    await persistence.updateAction(
      action.equalityKey,
      action,
    );

    // update the image in memory
    action.plant.image = Image.memory(imgBytes);
  }
}
