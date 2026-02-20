import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/logger/poke_logger.dart';

class AppLifecycleListener extends StatefulWidget {
  final Widget child;

  const AppLifecycleListener({super.key, required this.child});

  @override
  State<AppLifecycleListener> createState() => _AppLifecycleListenerState();
}

class _AppLifecycleListenerState extends State<AppLifecycleListener>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      GetIt.instance.get<PokeLogger>().logAppForegrounded();
    }
  }
}
