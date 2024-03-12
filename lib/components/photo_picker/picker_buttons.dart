import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';

typedef OnImageChosen = void Function(XFile);

class PickerButtons extends StatelessWidget {
  final double iconSize;
  final Color? color;
  final bool showText;
  final OnImageChosen onImageChosen;

  // https://pub.dev/packages/image_picker
  final ImagePicker picker;

  PickerButtons._({
    super.key,
    required this.iconSize,
    required this.showText,
    this.color,
    required this.onImageChosen,
    required this.picker,
  });

  factory PickerButtons.large({
    Key? key,
    Color? color,
    required OnImageChosen onImageChosen,
    required ImagePicker picker,
  }) {
    return PickerButtons._(
      key: key,
      iconSize: 70,
      showText: true,
      color: color,
      onImageChosen: onImageChosen,
      picker: picker,
    );
  }

  factory PickerButtons.small({
    Key? key,
    Color? color,
    required OnImageChosen onImageChosen,
    required ImagePicker picker,
  }) {
    return PickerButtons._(
      key: key,
      iconSize: 30,
      showText: false,
      color: color,
      onImageChosen: onImageChosen,
      picker: picker,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          PokeButton.icon(
            Icons.camera,
            iconSize: iconSize,
            text: showText ? "camera" : null,
            color: color,
            onPressed: () {
              _openCamera();
            },
          ),
          PokeConstants.FixedSpacer(4),
          PokeButton.icon(
            Icons.photo,
            iconSize: iconSize,
            text: showText ? "gallery" : null,
            color: color,
            onPressed: () {
              _openPhotoPicker();
            },
          ),
        ]);
  }

  void _openCamera() async {
    final XFile? media = await picker.pickImage(source: ImageSource.camera);
    if (media == null) {
      return;
    }

    onImageChosen(media);
  }

  void _openPhotoPicker() async {
    final XFile? media = await picker.pickImage(source: ImageSource.gallery);
    if (media == null) {
      return;
    }

    onImageChosen(media);
  }
}
