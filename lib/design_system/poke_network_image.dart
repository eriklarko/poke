import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/logger/poke_logger.dart';

class PokeNetworkImage extends Image {
  PokeNetworkImage(
    String src, {
    super.key,
    Color? color,
    Map<String, dynamic>? debugInfo,
  }) : super.network(
          src,
          loadingBuilder: (
            BuildContext context,
            Widget child,
            ImageChunkEvent? loadingProgress,
          ) {
            if (loadingProgress == null) return child;

            double? progress;
            // if expectedTotalBytes is null we can't know how much progress we've
            // made, and will display a forever-looping loading indicator by passing
            // `value: null` to PokeLoadingIndicator
            if (loadingProgress.expectedTotalBytes != null) {
              progress = loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!;
            }

            return Center(
              child: PokeLoadingIndicator.small(
                value: progress,
                color: color,
              ),
            );
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            final logData = {
              'error': error,
              'stackTrace': stackTrace,
              'imageUri': src,
            };
            if (debugInfo != null) {
              logData.addAll(debugInfo);
            }

            PokeLogger.instance().warn(
              "Unable to load plant image",
              data: logData,
            );

            return const Icon(Icons.broken_image);
          },
        );
}
