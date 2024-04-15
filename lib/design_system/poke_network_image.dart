import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_loading_indicator.dart';
import 'package:poke/logger/poke_logger.dart';

class PokeNetworkImage {
  static Image read(
    String src, {
    Key? key,
    Color? loadingIndicatorColor,
    Map<String, dynamic>? debugInfo,
  }) {
    return Image(
      image: CachedNetworkImageProvider(src),
      loadingBuilder: _loadingBuilder(loadingIndicatorColor),
      errorBuilder: _errorBuilder(src, debugInfo),
    );
  }

  static ImageLoadingBuilder _loadingBuilder(Color? loadingIndicatorColor) {
    return (
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
          color: loadingIndicatorColor,
        ),
      );
    };
  }

  static ImageErrorWidgetBuilder _errorBuilder(
    String src,
    Map<String, dynamic>? debugInfo,
  ) {
    return (
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
    };
  }
}
