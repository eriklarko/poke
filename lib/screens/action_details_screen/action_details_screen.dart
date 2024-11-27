import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/models/action.dart';
import 'package:poke/notifications/notification_service.dart';
import 'package:poke/persistence/persistence.dart';

class ActionDetailsScreen extends StatelessWidget {
  final notificationService = GetIt.instance.get<NotificationService>();
  final persistence = GetIt.instance.get<Persistence>();

  final Action action;
  final Widget body;

  ActionDetailsScreen({
    super.key,
    required this.action,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PokeAppBar(context),
      body: body,
    );
  }
}
