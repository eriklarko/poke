import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:poke/logger/local_logger.dart';

abstract class PokeLogger {
  static Map<String, dynamic> _staticData = {};

  static void addStaticData(String label, Map<String, dynamic> data) {
    _staticData.addAll(data.map((k, v) => MapEntry('$label.$k', v)));
  }

  static void removeStaticData(String label) {
    _staticData.removeWhere((k, v) => k.startsWith(label));
  }

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
  }) {
    if (_staticData.isNotEmpty) {
      data = data ?? {};
      data.addAll(_staticData);
    }

    return doLog(
      level,
      PokeLogEntry(
        level,
        msg,
        data: data,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @protected
  FutureOr<void> doLog(Level level, PokeLogEntry log);

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

class PokeLogEntry {
  final Level level;
  final String message;
  final Map<String, dynamic>? data;
  final Object? error;
  final StackTrace? stackTrace;

  PokeLogEntry(
    this.level,
    this.message, {
    this.data,
    this.error,
    this.stackTrace,
  });

  Map<String, String> asMap() {
    final d = Map<String, Object>.from(data ?? {});
    d['__msg'] = message;
    d['__level'] = level.toString();

    if (error != null) {
      d['__error'] = error!;
    }

    if (stackTrace != null) {
      d['__stackTrace'] = stackTrace!;
    }

    return d.map((k, v) => MapEntry(k, v.toString()));
  }

  @override
  toString() {
    return asMap().toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PokeLogEntry &&
        other.level == level &&
        other.message == message &&
        mapEquals(other.data, data) &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode {
    return level.hashCode ^
        message.hashCode ^
        (data?.hashCode ?? 0) ^
        (error?.hashCode ?? 0) ^
        (stackTrace?.hashCode ?? 0);
  }
}
