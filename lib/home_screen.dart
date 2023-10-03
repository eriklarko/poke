import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_app_bar.dart';

import 'components/upcoming_events_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(context) {
    return Scaffold(
      appBar: PokeAppBar(context, title: 'hiyo'),
      body: Column(children: [Text('hi')]),
    );
  }
}
