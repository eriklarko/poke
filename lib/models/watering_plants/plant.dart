import 'package:flutter/material.dart';

// TODO: this really really really needs to not include a network call
final defaultImage = Image.network('https://placekitten.com/40/40');

class Plant {
  final String name;
  late final Image? _image;

  Plant({required this.name, image}) {
    _image = image;
  }

  Image get image {
    return _image ?? defaultImage;
  }
}
