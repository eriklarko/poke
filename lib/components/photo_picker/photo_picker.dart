import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poke/components/photo_picker/picker_buttons.dart';
import 'package:poke/components/updating_widget/updating_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:poke/design_system/poke_tappable.dart';

import 'icon_button_with_triangular_background.dart';

// Should be called before calling any `image_picker` APIs
// see https://pub.dev/packages/image_picker_android#photo-picker
void enableAndroidPhotoPicker() {
  final ImagePickerPlatform imagePickerImplementation =
      ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
}

// Shows an image that can be replaced with a new one from the camera or gallery.
// It renders the image, and when the user taps it a row of buttons to edit the
// image is shown.
//   ┌───────────────────┐
//   |         ________  |
//   |   o    |   __   | |
//   |    \_O |  |__|  | |
//   | ___/ \ |___WW___| |
//   | __/  /     ||     |
//   |            ||     |
//   |------------||-----|
//   |      C  G  ||     | <- C = Camera button, G = Gallery button
//   └───────────────────┘
//
// If no image is passed into the constructor, it shows the camera and gallery
// buttons centered.
class PhotoPicker extends StatefulWidget {
  final Image? image;

  // used in tests to stub out the camera lib
  final ImagePicker imagePicker;
  // used in tests to stup out the file system
  final FileSystem fileSystem;

  // called whenever a new image is selected.
  final Future<void> Function(Uint8List imageBytes) onNewImage;

  PhotoPicker({
    super.key,
    this.image,
    required this.onNewImage,
    ImagePicker? imagePicker,
    FileSystem? fileSystem,
  })  : imagePicker = imagePicker ?? ImagePicker(),
        fileSystem = fileSystem ?? const LocalFileSystem() {
    enableAndroidPhotoPicker();
  }

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  final UpdatingWidgetController _controller = UpdatingWidgetController();
  bool _showPickerButtons = false;
  Widget? _image;

  @override
  void initState() {
    super.initState();
    _image = widget.image;
  }

  @override
  Widget build(BuildContext context) {
    return UpdatingWidget(
      controller: _controller,
      buildChild: (context) {
        if (_image == null) {
          return Center(
            child: PickerButtons.large(
              picker: widget.imagePicker,
              onImageChosen: _onNewImage,
            ),
          );
        } else {
          return _buildImageState(context);
        }
      },
    );
  }

  // Note: requires that `this._image` is not null
  Widget _buildImageState(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PokeTappable(
          key: const ValueKey('image-container'),
          onTap: () => _togglePickerButtons(),
          child: Container(
            constraints: const BoxConstraints.expand(),
            child: _image!,
          ),
        ),
        Container(
          alignment: Alignment.topRight,
          child: IconButtonWithTriangularBackground(
            icon: Icons.edit,
            size: 20,
            color: Colors.amber,
            onPressed: _togglePickerButtons,
          ),
        ),
        if (_showPickerButtons) _buildPickerButtons()
      ],
    );
  }

  Widget _buildPickerButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      padding: EdgeInsets.all(PokeConstants.space()),
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PickerButtons.small(
                picker: widget.imagePicker,
                color: Colors.white,
                onImageChosen: _onNewImage,
              ),
            ],
          ),
          Positioned.fill(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PokeButton.icon(
                  Icons.close,
                  onPressed: _togglePickerButtons,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _togglePickerButtons() {
    setState(() {
      _showPickerButtons = !_showPickerButtons;
    });
  }

  void _onNewImage(XFile newImageFile) async {
    _controller.setLoading();

    final f = widget.fileSystem.file(newImageFile.path);
    final newImageBytes = await f.readAsBytes();
    await widget.onNewImage(newImageBytes);
    setState(() {
      _controller.setDone();

      // hide picker buttons since they've fulfilled their use now
      _showPickerButtons = false;

      _image = Image.memory(newImageBytes);
    });
  }
}
