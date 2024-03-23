import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:poke/design_system/poke_network_image.dart';
import 'package:uuid/uuid.dart';

part "plant.g.dart";

/// Generates a string used to locate uploaded plant image data.
/// If no action id is passed, a random uuid will be used instead. This happens
/// eg. when an image is added before the action is created, because we don't
/// have an action id yet then.
///
/// This value is saved in persistent storage, so changing this implementation
/// might require migrating existing data to avoid dead data stored forever.
String newPlantImageStorageKey({
  String? actionId,
}) {
  late final String keyPrefix;
  if (actionId == null) {
    keyPrefix = GetIt.instance.get<Uuid>().v4();
  } else {
    keyPrefix = "action-$actionId";
  }

  return "$keyPrefix-plant-image";
}

@JsonSerializable()
class Plant {
  static final Image defaultImage = Image.asset(
    'assets/cat.jpeg',
    fit: BoxFit.cover,
  );

  final String id;
  final String name;

  Uri? _imageUri;
  Image? _cachedImage;

  Plant({
    required this.id,
    required this.name,
    Uri? imageUri,
  }) : _imageUri = imageUri;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Image get image {
    if (_cachedImage != null) {
      return _cachedImage!;
    }

    if (_imageUri == null) {
      _cachedImage = defaultImage;
    } else {
      _cachedImage = PokeNetworkImage(
        _imageUri.toString(),
        debugInfo: {'plant': this},
      );
    }
    return _cachedImage!;
  }

  Uri? get imageUri => _imageUri;
  set imageUri(Uri? u) {
    _cachedImage = null;
    _imageUri = u;
  }

  // NOTE! Setting the image this way does not make it persistent when the
  // action is updated. Use `set imageUri` instead for that
  //
  // this setter is only useful to change the image optimistically, in memory
  set image(Image i) {
    _cachedImage = i;
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

  @override
  bool operator ==(Object other) {
    if (other is! Plant) {
      return false;
    }

    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
