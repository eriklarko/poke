// TODO: turn into PokeEditableText?
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_async_button.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_text.dart';

class EditableTextField extends StatefulWidget {
  final String text;
  final FutureOr<void> Function(String)? onChanged;
  final double? iconSize;

  const EditableTextField(
    this.text, {
    super.key,
    this.onChanged,
    this.iconSize,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  final _inputController = TextEditingController();

  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _inputController.text = widget.text;
  }

  void enterEditMode() {
    setState(() {
      _editMode = true;
    });
  }

  void cancelEditMode() {
    setState(() {
      _editMode = false;
    });
  }

  FutureOr<void> updateText() async {
    await widget.onChanged!(_inputController.text);

    setState(() {
      _editMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_editMode) {
      return _buildEditMode();
    } else {
      return _buildTextMode();
    }
  }

  Widget _buildTextMode() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeText(_inputController.text),
        PokeButton.icon(
          Icons.edit,
          onPressed: enterEditMode,
          iconSize: widget.iconSize,
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
          ),
        ),
        PokeAsyncButton.icon(
          icon: Icons.save,
          iconSize: widget.iconSize,
          onPressed: () async {
            await updateText();
          },
        ),
        PokeButton.icon(
          Icons.cancel,
          onPressed: cancelEditMode,
          iconSize: widget.iconSize,
        ),
      ],
    );
  }
}
