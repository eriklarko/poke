import 'package:flutter/material.dart';

final Image defaultImage = Image.asset('assets/cat.jpeg');

class Plant {
  final String name;
  late final Image? _image;

  Plant({required this.name, image}) {
    _image = image;
  }

  Image get image {
    return _image ?? defaultImage;
  }

  @override
  String toString() {
    return name;
  }
}
