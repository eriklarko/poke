import 'dart:typed_data';

import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/models/action.dart';
import 'package:poke/models/watering_plants/editable_plant_image.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/persistence/in_memory_persistence.dart';
import 'package:poke/persistence/persistence.dart';

import '../../test_app.dart';
import '../../utils/images.dart';
import '../../utils/dependencies.dart';
import 'editable_plant_image_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Plant>(), MockSpec<Persistence>()])
void main() {
  Action.registerSubclasses();

  // The EditablePlantImage widget fills its parent by default, so we need to
  // put it in a context with a known size
  final testApp = pumpInTestAppFactory(
    (wut) => SizedBox.square(
      dimension: 200,
      child: wut,
    ),
  );

  testWidgets('shows the image', (tester) async {
    final action = WaterPlantAction(plant: MockPlant());

    final ImageProvider img = MemoryImage(Images.heartEyesEmojiBytes);
    when(action.plant.image).thenReturn(img);

    await testApp(
      tester,
      EditablePlantImage(action: action),
    );

    await tester.pumpAndSettle();

    expect(find.image(img), findsOneWidget);
  });

  testWidgets('updates the plant image uri', (tester) async {
    // create a plant showing "first-image.png"
    final plant = Plant(
      id: 'some-id',
      name: 'some-name',
      imageUri: Uri.file('first-image.png'),
    );
    final action = WaterPlantAction(plant: plant);

    // stub out persistence to return "updated-image.png"
    final persistence = MockPersistence();
    when(
      persistence.uploadData(
        any,
        newPlantImageStorageKey(actionId: action.equalityKey),
      ),
    ).thenAnswer(
      (_) async => Uri.file('updated-image.png'),
    );
    when(persistence.updateAction(action.equalityKey, action))
        .thenAnswer((_) async => action);
    setPersistence(persistence);

    // update the image
    final w = EditablePlantImage(action: action);
    // the argument to updateImage is irrelevant to the test as it's just
    // checking the URI
    await w.updateImage(Uint8List.fromList([1, 2, 3]));

    expect(
      plant.imageUri,
      equals(Uri.file('updated-image.png')),
    );
  });

  testWidgets('updates the plant image in memory', (tester) async {
    final plant = Plant(
      id: 'some-id',
      name: 'some-name',
      imageUri: Uri.file('first-image'),
    );
    final action = WaterPlantAction(plant: plant);

    final persistence = InMemoryPersistence();
    await persistence.createAction(action);
    setPersistence(persistence);

    final w = EditablePlantImage(action: action);
    await w.updateImage(Images.heartEyesEmojiBytes);

    expect(
      (plant.image as MemoryImage).bytes,
      equals(Images.heartEyesEmojiBytes),
    );
  });
}
