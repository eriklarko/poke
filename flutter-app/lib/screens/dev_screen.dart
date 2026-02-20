import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_app_bar.dart';

class DevScreen extends StatelessWidget {
  final Widget widget;

  const DevScreen({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: PokeAppBar(context), body: widget);
  }
}
