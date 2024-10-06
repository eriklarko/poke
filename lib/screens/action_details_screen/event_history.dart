import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/components/updating_widget/persistence_updating_widget.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/persistence/persistence.dart';

// TODO: turn into some nice plot showing the dates instead of a stupid list
class EventHistory extends StatelessWidget {
  final Action action;

  const EventHistory({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    var eventEntries = List.of(action.events.entries);

    return PersistenceUpdatingWidget<void>(
      actionId: action.equalityKey,
      initialData: null,
      buildChild: (context, _) => ListView.builder(
        key: super.key,
        itemCount: action.events.length,
        itemBuilder: ((context, index) {
          var entry = eventEntries[index];
          var date = entry.key;
          return Row(
            children: [
              PokeText("$date"),
              PokeButton.icon(
                Icons.delete,
                onPressed: () {
                  PokeLogger.instance().info(
                    'Deleting event',
                    data: {"event": entry},
                  );

                  _showConfirmationDialog(context, date);
                },
              )
            ],
          );
        }),
      ),
    );
  }

  _showConfirmationDialog(BuildContext context, DateTime eventTime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: PokeText("Delete event?"),
        content: PokeText(
          // TODO: Can this action be undone?
          "Do you really want to remove event $eventTime.\nTHIS ACTION CANNOT BE UNDONE",
        ),
        actions: [
          PokeButton.small(
            text: "yes",
            onPressed: () async {
              Navigator.of(context).pop();
              await GetIt.instance
                  .get<Persistence>()
                  .deleteEvent(action, eventTime);
              action.removeEvent(eventTime);
            },
          ),
          PokeButton.small(
            text: "no",
            onPressed: () {
              // close modal
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
