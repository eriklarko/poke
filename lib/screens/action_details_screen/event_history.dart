import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/persistence/persistence.dart';

class EventHistory extends StatelessWidget {
  final Action action;

  const EventHistory({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    var eventEntries = List.of(action.events.entries);

    return ListView.builder(
      key: super.key,
      itemCount: action.events.length,
      itemBuilder: ((context, index) {
        var entry = eventEntries[index];
        var date = entry.key;
        return Row(
          children: [
            PokeText("$date"),
            PokeButton.icon(Icons.delete, onPressed: () {
              PokeLogger.instance().info(
                'Deleting event',
                data: {"event": entry},
              );

              GetIt.instance.get<Persistence>().deleteEvent(action, date);
            })
          ],
        );
      }),
    );
  }
}
