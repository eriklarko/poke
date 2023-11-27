import 'package:flutter/material.dart';

class DevScreen extends StatelessWidget {
  final Widget widget;

  const DevScreen({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: widget);
  }
}
