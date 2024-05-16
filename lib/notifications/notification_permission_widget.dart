// Shows a small bar asking the user to allow notifications. If notifications
// are allowed nothing is shown
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:poke/design_system/poke_async_button.dart';
import 'package:poke/design_system/poke_constants.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/design_system/poke_text.dart';
import 'package:poke/logger/poke_logger.dart';
import './notification_service.dart';

class NotificationPermissionWidget extends StatefulWidget {
  static const widgetKey = ValueKey('notification-permission-widget');

  final bool _takeUpSpaceWhileLoading;

  const NotificationPermissionWidget({
    super.key,
    bool takeUpSpaceWhileLoading = false,
  }) : _takeUpSpaceWhileLoading = takeUpSpaceWhileLoading;

  @override
  State<NotificationPermissionWidget> createState() =>
      _NotificationPermissionWidgetState();
}

class _NotificationPermissionWidgetState
    extends State<NotificationPermissionWidget> {
  final _notificationService = GetIt.instance.get<NotificationService>();

  void _rerender() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final FutureOr<PermissionResponse> val =
        _notificationService.hasPermissionToSendNotifications();

    if (val is Future<PermissionResponse>) {
      return _buildWithFutureBuilder(val);
    } else {
      return _build(context, val);
    }
  }

  FutureBuilder<PermissionResponse> _buildWithFutureBuilder(
    Future<PermissionResponse> future,
  ) {
    // TODO: Try to avoid jank by making sure loading and error states takes up as much space as the question-and-buttons widget
    return FutureBuilder<PermissionResponse>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // loading is done, show the same as if NotificationService didn't
          // return a promise
          return _build(context, snapshot.data!);
        }

        if (snapshot.hasError) {
          PokeLogger.instance()
              .error("Failed reading notification permission", data: {
            'error': snapshot.error,
          });

          return Row(
            children: [
              const Icon(Icons.error),
              PokeConstants.FixedSpacer(),
              PokeFinePrint(
                  "Failed reading notification permission: ${snapshot.error}"),
            ],
          );
        }

        if (widget._takeUpSpaceWhileLoading) {
          return const Center(
            child: PokeLoadingIndicator.small(),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget _build(
    BuildContext context,
    PermissionResponse decision,
  ) {
    if (decision == PermissionResponse.allowed ||
        decision == PermissionResponse.denied) {
      // render nothing if the user has chosen already
      return Container();
    }

    return Column(
      key: NotificationPermissionWidget.widgetKey,
      children: [
        Row(
          children: [
            const Icon(Icons.warning),
            PokeConstants.FixedSpacer(),
            Expanded(
              child: PokeText(
                "Poke wants to send notifications to remind you of things.",
              ),
            ),
          ],
        ),
        PokeAsyncButton.once(
          key: const ValueKey('decide-button'),
          onPressed: () async {
            await _notificationService.decidePermissionsToSendNotifications();
            _rerender();
          },
          text: "Decide!",
          usePrimaryButton: false,
        ),
      ],
    );
  }
}
