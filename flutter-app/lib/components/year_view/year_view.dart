import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:intl/intl.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_tappable.dart';
import 'package:poke/design_system/poke_text.dart';

/// Renders a year view with days as columns and months as rows
/// The cells contain a circle whose size is proportional to the number of
/// events that happened on that day.
///
/// +-----+---------+----------+-----------+-----------+
/// |     |  1 - 8  |  9 - 16  |  17 - 24  |  25 - 31  |
/// +-----+---------+----------+-----------+-----------+
/// | Jan |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Feb |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Mar |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Apr |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | May |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Jun |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Jul |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Aug |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Sep |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Oct |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Nov |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
/// | Dec |         |          |           |           |
/// +-----+---------+----------+-----------+-----------+
class YearView extends StatelessWidget {
  final Iterable<DateTime> eventTimes;
  final Null Function(
    Iterable<DateTime> events,
    DateTime start,
    DateTime end,
  )? onCellTap;

  final bool includeHeader;
  final int daysPerColumn;
  final int rowHeight;
  final BorderSide border = BorderSide(color: PokeConstants.colors.outline);
  late final int rows;
  late final int cols;

  YearView({
    super.key,
    required this.eventTimes,
    this.onCellTap,
    this.includeHeader = true,
    this.daysPerColumn = 7,
    this.rowHeight = 30,
  }) {
    rows = includeHeader ? 13 : 12;
    cols = 31 ~/ daysPerColumn + 1; // +1 for the months
  }

  @override
  Widget build(BuildContext context) {
    return LayoutGrid(
      //columnSizes: [auto, 1.fr, 1.fr, 1.fr, 1.fr],
      columnSizes: List.filled(cols, 1.fr)..[0] = auto,
      // don't want to set height explicitly, but auto doesn't fit the text
      // snugly so... fuck life
      rowSizes: List.generate(rows, (_) => rowHeight.px),
      columnGap: 0,
      rowGap: 0,
      children: List.generate(rows * cols, (childIndex) {
        final row = childIndex ~/ cols;
        final col = childIndex % cols;

        return renderCell(row, col);
      }),
    );
  }

  Widget renderCell(int row, int col) {
    final firstDay = daysPerColumn * (col - 1) + col;
    final lastDay = min(daysPerColumn * col + col, 31);

    final eventsInCell = eventTimes.where((eventTime) {
      final month = eventTime.month;
      if (month != row) {
        return false;
      }
      final day = eventTime.day;
      return day >= firstDay && day <= lastDay;
    }).toList();

    if (row == 0 && col == 0) {
      return renderTopLeftCornerCell();
    }

    if (row == 0) {
      return renderHeaderCell(col, firstDay, lastDay);
    }

    if (col == 0) {
      return renderMonthCell(row);
    }

    return renderDayCell(row, col, eventsInCell);
  }

  Widget renderTopLeftCornerCell() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: border, right: border),
      ),
    );
  }

  Widget renderMonthCell(int row) {
    final month = includeHeader ? row : row + 1;
    return Container(
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        border: month == 12
            ? Border(
                right: border,
              )
            : Border(
                right: border,
                bottom: border,
              ),
      ),
      padding: EdgeInsets.only(right: PokeConstants.space()),
      child: PokeText(
        DateFormat('MMM').format(DateTime(0, month)),
      ),
    );
  }

  Widget renderHeaderCell(
    int col,
    int firstDay,
    int lastDay,
  ) {
    return Container(
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        border: isLastColumn(col)
            ? Border(bottom: border)
            : Border(bottom: border, right: border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: PokeConstants.space()),
        child: firstDay == lastDay
            ? PokeText("$firstDay")
            : PokeText("$firstDay - $lastDay"),
      ),
    );
  }

  Widget renderDayCell(int row, int col, List<DateTime> eventsInCell) {
    // Render cell
    final omgThisSucks2 = isLastRow(row)
        ? Border(
            // no bottom border on for December
            right: border,
          )
        : isLastColumn(col)
            ? Border(
                bottom: border,
              )
            : Border(
                right: border,
                bottom: border,
              );
    // Read doc on `radius` in RadialGradient for more info on
    // circleSizeFactor
    final circleSizeFactor = eventsInCell.length / 10;
    final w = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: omgThisSucks2,
        gradient: RadialGradient(
          center: Alignment.center,
          radius: circleSizeFactor,
          colors: [
            PokeConstants.colors.primary,
            PokeConstants.colors.primary.withOpacity(0),
          ],
          stops: [0.5, 1.0],
        ),
      ),
    );

    if (onCellTap == null) {
      return w;
    }
    return PokeTappable(
      onTap: () => _onCellTap(row, col, eventsInCell),
      child: w,
    );
  }

  _onCellTap(int row, int col, Iterable<DateTime> eventsInCell) {
    if (onCellTap != null) {
      final startDate = DateTime(0, row, daysPerColumn * (col - 1) + col);
      final endDate = DateTime(0, row, min(daysPerColumn * col + col, 31));

      onCellTap!(eventsInCell, startDate, endDate);
    }
  }

  bool isLastColumn(int col) => col == cols - 1;
  bool isLastRow(int row) => row == rows - 1;
}
