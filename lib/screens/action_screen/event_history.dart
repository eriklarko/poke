import 'package:calendar_view/calendar_view.dart';
import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:poke/components/updating_widget/persistence_updating_widget.dart';
import 'package:poke/components/year_view/year_view.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_modal.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/design_system/poke_time_ago.dart';
import 'package:poke/logger/poke_logger.dart';
import 'package:poke/models/action.dart';
import 'package:poke/persistence/persistence.dart';
import 'package:poke/persistence/serializable_event_data.dart';

class EventHistory<T extends SerializableEventData?> extends StatelessWidget {
  final Action<T> action;

  const EventHistory({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    return PersistenceUpdatingWidget<void>(
      actionId: action.equalityKey,
      initialData: null,
      buildChild: (context, _) {
        final eventEntries = List.of(action.events.entries);
        final sorted = sortDateAsc(eventEntries);
        final timeSinceOldestEvent = clock.now().difference(
              sorted.firstOrNull?.key ?? clock.now(),
            );

        final newestEvent = sorted.firstOrNull?.key ?? clock.now();
        final events =
            sorted.where((element) => element.key.year == newestEvent.year);

        if (timeSinceOldestEvent.inDays < 31) {
          return monthView(context, events);
        } else {
          //return yearView(context, sorted);
          return YearView(
            eventTimes: events.map((e) => e.key),
            onCellTap: (events, DateTime start, DateTime end) {
              openEventListModal(
                context,
                PokeText("${events.length} event(s) on $start - $end"),
                events,
              );
            },
            daysPerColumn: 6,
          );
        }
      },
    );
  }

  Iterable<MapEntry<DateTime, T?>> sortDateAsc(
    Iterable<MapEntry<DateTime, T?>> events,
  ) {
    return events.sorted((a, b) {
      return a.key.compareTo(b.key);
    });
  }

  Widget monthView(
    BuildContext context,
    Iterable<MapEntry<DateTime, T?>> sortedEventEntries,
  ) {
    final ec = EventController<T>();
    ec.addAll(
      sortedEventEntries
          .map(
            (e) => CalendarEventData<T>(
              title: " ",
              date: e.key,
              event: e.value,
            ),
          )
          .toList(),
    );

    return MonthView(
      controller: ec,
      minMonth: sortedEventEntries.firstOrNull?.key,
      initialMonth: clock.now(),
      onCellTap: (events, date) {
        openEventListModal(
          context,
          PokeText("${events.length} event(s) on ${date.toIso8601String()}"),
          events.map((cea) => cea.date),
        );
      },
      onEventTap: (event, date) {
        openEventModal(context, date);
      },
    );
  }

  void openEventListModal(
    BuildContext context,
    Widget header,
    Iterable<DateTime> events,
  ) {
    final m = PokeModal(
      child: Column(
        children: [
          header,
          ...events.map((event) {
            return Row(
              children: [
                PokeTimeAgo(date: event),
                PokeButton.icon(
                  Icons.delete,
                  onPressed: () {
                    PokeLogger.instance().info(
                      'Deleting event',
                      data: {"event": event},
                    );

                    _showDeleteEventConfirmationDialog(context, event);
                  },
                )
              ],
            );
          }),
        ],
      ),
    );
    m.show(context);
  }

  void openEventModal(BuildContext context, DateTime date) {
    final m = PokeModal(
      child: Row(
        children: [
          PokeTimeAgo(date: date),
          PokeButton.icon(
            Icons.delete,
            onPressed: () {
              PokeLogger.instance().info(
                'Deleting event',
                data: {"event": date},
              );

              _showDeleteEventConfirmationDialog(context, date);
            },
          )
        ],
      ),
    );
    m.show(context);
  }

  _showDeleteEventConfirmationDialog(BuildContext context, DateTime eventTime) {
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
