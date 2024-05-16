import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/models/watering_plants/new_instance_widget.dart';
import 'package:poke/models/watering_plants/plant.dart';
import 'package:poke/models/watering_plants/water_plant.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:uuid/uuid.dart';

import '../../test_app.dart';
import '../../utils/dependencies.dart';
import 'new_instance_widget_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Persistence>(), MockSpec<Uuid>()])
void main() {
  final pumpInTestApp =
      pumpInTestAppFactory((wut) => SingleChildScrollView(child: wut));

  testWidgets("data inputted gets sent to persistence correctly",
      (tester) async {
    final persistence = MockPersistence();
    when(persistence.uploadData(any, any)).thenAnswer(
      (_) async => Uri.file('/foo'),
    );

    // unfortunate dependency
    setDependency<Uuid>(const Uuid());

    await pumpInTestApp(
      tester,
      NewInstanceWidget(persistence: persistence),
    );

    // enter plant name
    final inputField = find.byKey(const ValueKey("plant-name"));
    await tester.ensureVisible(inputField);
    await tester.enterText(
      inputField,
      "some-plant-name",
    );

    // set plant image
    await _uploadTestImage(tester);

    // press `create` button
    final createButton = find.text('Create');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);

    verify(
      persistence.createAction(
        WaterPlantAction(
          plant: Plant(
            id: "some-plant-name".hashCode.toString(),
            name: "some-plant-name",
            imageUri: Uri.file('/foo'),
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets("uploads image", (tester) async {
    final persistence = MockPersistence();

    // `newPlantImageStorageKey` uses a uuid (v4) internally. to be able to test
    // the upload we hijack the uuid generation to always return the same id
    final mockUuid = MockUuid();
    when(mockUuid.v4()).thenReturn('123');
    setDependency<Uuid>(mockUuid);

    await pumpInTestApp(
      tester,
      NewInstanceWidget(persistence: persistence),
    );

    // set plant image
    final imageBytes = await _uploadTestImage(tester);

    final storageKey = newPlantImageStorageKey();
    verify(persistence.uploadData(imageBytes, storageKey)).called(1);
  });

  testWidgets('submit button is disabled while uploading image',
      (tester) async {
    final c = Completer<Uri>();
    final persistence = MockPersistence();
    when(persistence.uploadData(any, any)).thenAnswer(
      (_) => c.future,
    );

    // unfortunate dependency
    setDependency<Uuid>(const Uuid());

    await pumpInTestApp(
      tester,
      NewInstanceWidget(persistence: persistence),
    );

    final createButton = find.byType(TextButton);
    // check button is enabled before uploading
    expect(
      tester.widget<TextButton>(createButton).onPressed,
      isNotNull,
    );

    // trigger image upload. use `c.complete(...)` to finish upload
    _uploadTestImage(tester);
    await tester.pump();

    // check button is disabled while uploading
    expect(
      tester.widget<TextButton>(createButton).onPressed,
      isNull,
    );

    // finish upload an ensure button is enabled again
    c.complete(Uri.file('/foo'));
    await tester.pump();
    expect(
      tester.widget<TextButton>(createButton).onPressed,
      isNotNull,
    );
  });
}

Future<Uint8List> _uploadTestImage(WidgetTester tester) async {
  final imageBytes = Uint8List.fromList([1, 2, 3]);

  final NewInstanceWidgetState state = tester.state(
    find.byType(NewInstanceWidget),
  );
  await state.uploadImage(imageBytes);

  return imageBytes;
}
