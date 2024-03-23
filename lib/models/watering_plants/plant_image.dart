import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:poke/components/photo_picker/photo_picker.dart';

// Used to ensure plant images are a consistent size and have consistent
// decoration
class PlantImage extends StatelessWidget {
  final Future<void> Function(Uint8List)? onNewImage;
  final Image? image;
  final double maxWidth;
  final double maxHeight;

  const PlantImage.large({
    super.key,
    this.onNewImage,
    this.image,
  })  : maxWidth = 500,
        maxHeight = 500;

  const PlantImage.fill({
    super.key,
    this.onNewImage,
    this.image,
  })  : maxWidth = double.infinity,
        maxHeight = double.infinity;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: onNewImage == null
            ? image
            : PhotoPicker(
                onNewImage: onNewImage!,
                image: image,
              ),
      ),
    );
  }
}
