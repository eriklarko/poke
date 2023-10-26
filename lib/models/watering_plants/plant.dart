import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part "plant.g.dart";

final Image defaultImage = Image.asset('assets/cat.jpeg');

@JsonSerializable()
class Plant {
  final String id;
  final String name;
  late final Image? _image;

  Plant({required this.id, required this.name, image}) {
    _image = image;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  Image get image {
    return _image ?? defaultImage;
  }

  @override
  String toString() {
    return name;
  }

  Map<String, dynamic> toJson() {
    return _$PlantToJson(this);
  }

  factory Plant.fromJson(Map<String, dynamic> json) {
    return _$PlantFromJson(json);
  }
}
