import 'dart:async';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:poke/logger/local_logger.dart';

abstract class PokeLogger {
  FutureOr<void> logAppForegrounded();

  FutureOr<void> trace(String msg, {Map<String, dynamic>? data}) {
    return log(Level.trace, msg, data: data);
  }

  FutureOr<void> debug(String msg, {Map<String, dynamic>? data}) {
    return log(Level.debug, msg, data: data);
  }

  FutureOr<void> info(String msg, {Map<String, dynamic>? data}) {
    return log(Level.info, msg, data: data);
  }

  FutureOr<void> warn(String msg, {Map<String, dynamic>? data}) {
    return log(Level.warning, msg, data: data);
  }

  FutureOr<void> error(
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return log(
      Level.error,
      msg,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  FutureOr<void> fatal(
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return log(
      Level.fatal,
      msg,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  FutureOr<void> log(
    Level level,
    String msg, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  });

  static PokeLogger instance() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return LocalLogger();
    }
    if (!GetIt.instance.isRegistered<PokeLogger>()) {
      final logger = LocalLogger();
      logger.warn('PokeLogger not registered in GetIt. this is odd.');
      return logger;
    }
    return GetIt.instance.get<PokeLogger>();
  }
}
