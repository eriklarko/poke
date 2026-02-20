import 'package:flutter/material.dart';
import 'package:poke/components/reminder_list/sortable_fields.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_constants.dart';

// Renders a row of buttons that allow the user to select a field to sort by.
// The selected field will be highlighted by an arrow indicating the sort
// direction.
//
// The `onSort` callback will be called whenever the user selects a field to
// sort by. The callback will receive the selected field and the sort direction.
//
// The `initialSort` parameter can be used to set the initial sort field and
// direction.
//
// Example sorting by some field B in descending order:
//   +-----------------------+
//   | [SortByA] [SortByB] V |
//   +-----------------------+
class SortOrderSelector<T> extends StatefulWidget {
  final Iterable<SortableField<T>> sortFields;
  final (SortableField<T> field, SortDirection direction)? initialSort;
  final Function(SortableField<T> field, SortDirection direction) onSort;

  const SortOrderSelector({
    super.key,
    required this.sortFields,
    required this.onSort,
    this.initialSort,
  });

  @override
  State<SortOrderSelector<T>> createState() => _SortOrderSelectorState<T>();
}

class _SortOrderSelectorState<T> extends State<SortOrderSelector<T>> {
  SortableField<T>? _selectedField;
  SortDirection? _direction;

  @override
  @override
  void initState() {
    super.initState();
    _selectedField = widget.initialSort?.$1;
    _direction = widget.initialSort?.$2;
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final field in widget.sortFields) {
      children.add(
        PokeButton.icon(
          field.icon,
          key: field.key,
          onPressed: () => _onFieldSelected(field),
          color: PokeConstants.colors.primary,
          iconSize: 30,
        ),
      );

      if (field == _selectedField) {
        children.add(Icon(
          _direction == SortDirection.ascending
              ? Icons.arrow_drop_up
              : Icons.arrow_drop_down,
          color: PokeConstants.colors.primary,
        ));
      } else {
        // add a transparent icon to keep the layout consistent
        children.add(Icon(Icons.arrow_drop_down, color: Colors.transparent));
      }

      children.add(PokeConstants.fixedSpacer());
    }
    children.removeLast();

    return Row(
      children: children,
    );
  }

  _onFieldSelected(SortableField<T> field) {
    setState(() {
      if (_selectedField == field) {
        _direction = _direction == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending;
      } else {
        _selectedField = field;
        _direction = widget.initialSort?.$2 ?? SortDirection.ascending;
      }

      widget.onSort(_selectedField!, _direction!);
    });
  }
}

enum SortDirection { ascending, descending }
