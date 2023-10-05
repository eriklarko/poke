import 'package:flutter/material.dart';

class PokeCheckbox extends StatefulWidget {
  final _PokeCheckboxState _state = _PokeCheckboxState();

  PokeCheckbox({Key? key}) : super(key: key);

  @override
  State<PokeCheckbox> createState() => _state;

  bool get isChecked {
    return _state.isChecked;
  }
}

class _PokeCheckboxState extends State<PokeCheckbox> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: isChecked,
      onChanged: (bool? value) {
        setState(() {
          isChecked = value!;
        });
      },
    );
  }
}
