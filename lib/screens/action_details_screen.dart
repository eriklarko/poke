import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_app_bar.dart';

class ActionDetailsScreen extends StatelessWidget {
  final Widget body;

  const ActionDetailsScreen({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: PokeAppBar(context), body: body);
  }
}
