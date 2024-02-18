import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/persistence/action_with_events.dart';
import 'package:poke/persistence/persistence.dart';

class EventHistory extends StatelessWidget {
  final ActionWithEvents actionWithEvents;

  const EventHistory({super.key, required this.actionWithEvents});

  @override
  Widget build(BuildContext context) {
    var eventEntries = List.of(actionWithEvents.events.entries);

    return ListView.builder(
      key: super.key,
      itemCount: actionWithEvents.events.length,
      itemBuilder: ((context, index) {
        var entry = eventEntries[index];
        var date = entry.key;
        return Row(
          children: [
            PokeText("$date"),
            PokeButton.icon(const Icon(Icons.delete), onPressed: () {
              PokeLogger.instance()
                  .info('Deleting event', data: {"event": entry});

              GetIt.instance
                  .get<Persistence>()
                  .deleteEvent(actionWithEvents.action, date);
            })
          ],
        );
      }),
    );
  }
}
