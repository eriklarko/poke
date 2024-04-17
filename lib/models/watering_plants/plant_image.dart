import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:poke/components/photo_picker/photo_picker.dart';
import 'package:poke/design_system/poke_network_image.dart';
import 'package:crypto/crypto.dart';

// Used to ensure plant images are a consistent size and have consistent
// decoration
class PlantImage extends StatelessWidget {
  static const ImageProvider defaultImage = AssetImage('assets/cat.jpeg');

  final Future<void> Function(Uint8List)? onNewImage;
  final ImageProvider? image;
  final double maxWidth;
  final double maxHeight;

  const PlantImage.large(
    this.image, {
    super.key,
    this.onNewImage,
  })  : maxWidth = 500,
        maxHeight = 500;

  const PlantImage.fill(
    this.image, {
    super.key,
    this.onNewImage,
  })  : maxWidth = double.infinity,
        maxHeight = double.infinity;

  @override
  Widget build(BuildContext context) {
    final i = PokeNetworkImage.build(
      image: image ?? defaultImage,
      fit: BoxFit.cover,
      debugInfo: {
        'imageUri': _attemptToGetImageSource(image),
      },
    );

    return AspectRatio(
      aspectRatio: 1 / 1,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: onNewImage == null
            ? i
            : PhotoPicker(
                onNewImage: onNewImage!,
                image: i,
              ),
      ),
    );
  }

  String _attemptToGetImageSource(ImageProvider? image) {
    if (image is NetworkImage) {
      return image.url;
    }
    if (image is CachedNetworkImageProvider) {
      return image.url;
    }
    if (image is MemoryImage) {
      return "md5:${md5.convert(image.bytes)}";
    }
    if (image is AssetImage) {
      return image.assetName;
    }

    return 'unsupported image type: ${image.runtimeType}';
  }
}
