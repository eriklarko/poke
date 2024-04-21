import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:poke/components/photo_picker/photo_picker.dart';
import 'package:poke/design_system/poke_tappable.dart';

import '../../mock_callback.dart';
import '../../test_app.dart';
import '../../utils/images.dart';
import 'photo_picker_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ImagePicker>()])
void main() async {
  final Image testImage = Image.memory(Images.heartEyesEmojiBytes);

  // the photo picker expands to fill its parent, so we need its parent to have
  // a known size. Using SizedBox here is simple
  final testApp = pumpInTestAppFactory(
    (wut) => SizedBox(
      width: 300,
      height: 300,
      child: wut,
    ),
  );

  testWidgets(
      'Shows large gallery and camera icons when no picture is provided',
      (tester) async {
    await testApp(
      tester,
      PhotoPicker(
        onNewImage: (_) async {},
      ),
    );

    expectPickerButtonsShown();
  });

  testWidgets('Shows the picture passed to it initially', (tester) async {
    await testApp(
      tester,
      PhotoPicker(
        image: testImage,
        onNewImage: (_) async {},
      ),
    );

    expect(find.image(testImage.image), findsOneWidget);
  });

  testWidgets('Does not show picker buttons when giving an image initially',
      (tester) async {
    await testApp(
      tester,
      PhotoPicker(
        image: testImage,
        onNewImage: (_) async {},
      ),
    );

    expectPickerButtonsHidden();
  });

  testWidgets('Toggles picker buttons when tapping image', (tester) async {
    await testApp(
      tester,
      PhotoPicker(
        image: testImage,
        onNewImage: (_) async {},
      ),
    );

    expectPickerButtonsHidden();

    // tap to show buttons
    await tester.tap(find.byType(PhotoPicker));
    await tester.pumpAndSettle();
    expectPickerButtonsShown();

    // tap to hide buttons
    await tester.tap(find.byType(PhotoPicker));
    await tester.pumpAndSettle();
    expectPickerButtonsHidden();
  });

  testWidgets("Invokes onNewImage", (tester) async {
    // stub out picking a photo from the camera/gallery
    final fileSystem = MemoryFileSystem();
    final pickerMock = MockImagePicker();
    when(pickerMock.pickImage(source: ImageSource.camera)).thenAnswer(
      (_) => setupFakeFileWithImage(
        fileSystem,
        Images.redCircleBytes,
        'some-image-name',
      ),
    );

    final onNewImageCb = MockSingleArgCallback<Uint8List>();

    await testApp(
      tester,
      PhotoPicker(
        image: testImage,
        imagePicker: pickerMock,
        fileSystem: fileSystem,
        onNewImage: (a) async => onNewImageCb(a),
      ),
    );

    // bring up picker buttons
    await tester.tap(find.byType(PhotoPicker));
    await tester.pumpAndSettle();
    // select new image
    await tester.tap(find.byIcon(Icons.camera));

    // verify callback was invoked with correct data
    verify(onNewImageCb(Images.redCircleBytes)).called(1);
  });

  testWidgets("Picker buttons disappear after selecing new image",
      (tester) async {
    // stub out picking a photo from the camera/gallery
    final fileSystem = MemoryFileSystem();
    final pickerMock = MockImagePicker();
    when(pickerMock.pickImage(source: ImageSource.camera)).thenAnswer(
      (_) => setupFakeFileWithImage(
        fileSystem,
        Images.redCircleBytes,
        'some-image-name',
      ),
    );

    await testApp(
      tester,
      PhotoPicker(
        image: testImage,
        imagePicker: pickerMock,
        fileSystem: fileSystem,
        onNewImage: (_) async {},
      ),
    );

    // bring up picker buttons
    await tester.tap(find.byType(PhotoPicker));
    await tester.pumpAndSettle();
    // select new image
    await tester.tap(find.byIcon(Icons.camera));
    await tester.pumpAndSettle();

    expectPickerButtonsHidden();
  });
}

Future<XFile?> setupFakeFileWithImage(
  FileSystem fileSystem,
  Uint8List img,
  String name,
) async {
  final f = fileSystem.file(name);
  await f.writeAsBytes(img);

  return XFile(name);
}

void expectPickerButtonsShown() {
  _expectPickerButtons(findsOneWidget);
}

void expectPickerButtonsHidden() {
  _expectPickerButtons(findsNothing);
}

void _expectPickerButtons(Matcher m) {
  expect(find.byIcon(Icons.camera), m);
  expect(find.byIcon(Icons.photo), m);
}
