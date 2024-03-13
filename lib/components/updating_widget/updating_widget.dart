import 'package:flutter/material.dart' hide Overlay;
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_text.dart';

import 'overlay.dart';

// A widget that can show a loading or error indicator above another widget.
// useful for widgets that display data that can be updated
class UpdatingWidget extends StatefulWidget {
  final UpdatingWidgetController controller;

  final Widget Function(BuildContext) buildChild;

  const UpdatingWidget({
    super.key,
    required this.controller,
    required this.buildChild,
  });

  @override
  State<UpdatingWidget> createState() => _UpdatingWidgetState();
}

class UpdatingWidgetController {
  _UpdatingWidgetState? _state;

  void _setState(_UpdatingWidgetState newState) {
    _state = newState;
  }

  void setLoading() {
    _state!.setLoading();
  }

  void setDone() {
    _state!.setDone();
  }

  void setError(String error) {
    _state!.setError(error);
  }
}

class _UpdatingWidgetState extends State<UpdatingWidget> {
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    widget.controller._setState(this);
  }

  void setLoading() {
    setState(() {
      _loading = true;
    });
  }

  void setDone() {
    setState(() {
      _loading = false;
    });
  }

  void setError(String error) {
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget w = widget.buildChild(context);

    if (_error != null) {
      return _showInfoOnTop(
        w,
        Column(
          children: [
            const Icon(Icons.error),
            PokeText("$_error"),
          ],
        ),
      );
    }

    if (_loading) {
      return _showInfoOnTop(
        w,
        // The loading indicator color needs to have high contrast against `Overlay(..)`
        const PokeLoadingIndicator.small(color: Colors.white),
      );
    }

    return w;
  }

  Widget _showInfoOnTop(Widget base, Widget info) {
    return Stack(children: [
      base,
      Overlay(child: info),
    ]);
  }
}
