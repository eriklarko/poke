import 'dart:convert';
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
import 'photo_picker_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ImagePicker>()])
void main() async {
  const String heartEyesEmojiBase64 =
      "iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAApgAAAKYB3X3/OAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAANCSURBVEiJtZZPbBtFFMZ/M7ubXdtdb1xSFyeilBapySVU8h8OoFaooFSqiihIVIpQBKci6KEg9Q6H9kovIHoCIVQJJCKE1ENFjnAgcaSGC6rEnxBwA04Tx43t2FnvDAfjkNibxgHxnWb2e/u992bee7tCa00YFsffekFY+nUzFtjW0LrvjRXrCDIAaPLlW0nHL0SsZtVoaF98mLrx3pdhOqLtYPHChahZcYYO7KvPFxvRl5XPp1sN3adWiD1ZAqD6XYK1b/dvE5IWryTt2udLFedwc1+9kLp+vbbpoDh+6TklxBeAi9TL0taeWpdmZzQDry0AcO+jQ12RyohqqoYoo8RDwJrU+qXkjWtfi8Xxt58BdQuwQs9qC/afLwCw8tnQbqYAPsgxE1S6F3EAIXux2oQFKm0ihMsOF71dHYx+f3NND68ghCu1YIoePPQN1pGRABkJ6Bus96CutRZMydTl+TvuiRW1m3n0eDl0vRPcEysqdXn+jsQPsrHMquGeXEaY4Yk4wxWcY5V/9scqOMOVUFthatyTy8QyqwZ+kDURKoMWxNKr2EeqVKcTNOajqKoBgOE28U4tdQl5p5bwCw7BWquaZSzAPlwjlithJtp3pTImSqQRrb2Z8PHGigD4RZuNX6JYj6wj7O4TFLbCO/Mn/m8R+h6rYSUb3ekokRY6f/YukArN979jcW+V/S8g0eT/N3VN3kTqWbQ428m9/8k0P/1aIhF36PccEl6EhOcAUCrXKZXXWS3XKd2vc/TRBG9O5ELC17MmWubD2nKhUKZa26Ba2+D3P+4/MNCFwg59oWVeYhkzgN/JDR8deKBoD7Y+ljEjGZ0sosXVTvbc6RHirr2reNy1OXd6pJsQ+gqjk8VWFYmHrwBzW/n+uMPFiRwHB2I7ih8ciHFxIkd/3Omk5tCDV1t+2nNu5sxxpDFNx+huNhVT3/zMDz8usXC3ddaHBj1GHj/As08fwTS7Kt1HBTmyN29vdwAw+/wbwLVOJ3uAD1wi/dUH7Qei66PfyuRj4Ik9is+hglfbkbfR3cnZm7chlUWLdwmprtCohX4HUtlOcQjLYCu+fzGJH2QRKvP3UNz8bWk1qMxjGTOMThZ3kvgLI5AzFfo379UAAAAASUVORK5CYII=";
  final Image testImage = Image.memory(base64Decode(heartEyesEmojiBase64));

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
    await tester.tap(find.byType(PokeTappable));
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
    final newImageBytes = base64Decode(
      "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==",
    );
    when(pickerMock.pickImage(source: ImageSource.camera)).thenAnswer(
      (_) => setupFakeFileWithImage(
        fileSystem,
        newImageBytes,
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
    await tester.tap(find.byType(PokeTappable));
    await tester.pumpAndSettle();
    // select new image
    await tester.tap(find.byIcon(Icons.camera));

    // verify callback was invoked with correct data
    verify(onNewImageCb(newImageBytes)).called(1);
  });

  testWidgets("Picker buttons disappear after selecing new image",
      (tester) async {
    // stub out picking a photo from the camera/gallery
    final fileSystem = MemoryFileSystem();
    final pickerMock = MockImagePicker();
    final newImageBytes = base64Decode(
      "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==",
    );
    when(pickerMock.pickImage(source: ImageSource.camera)).thenAnswer(
      (_) => setupFakeFileWithImage(
        fileSystem,
        newImageBytes,
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
    await tester.tap(find.byType(PokeTappable));
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
