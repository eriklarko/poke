import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:poke/logger/local_logger.dart';

abstract interface class PokeLogger {
  Future logAppForegrounded();

  Future trace(String msg, {Map<String, dynamic>? data});
  Future debug(String msg, {Map<String, dynamic>? data});
  Future info(String msg, {Map<String, dynamic>? data});
  Future warn(String msg, {Map<String, dynamic>? data});
  Future error(
    String msg, {
    Map<String, dynamic> data,
    Object? error,
    StackTrace? stackTrace,
  });
  Future fatal(
    String msg, {
    Map<String, dynamic> data,
    Object? error,
    StackTrace? stackTrace,
  });
  Future log(
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
    return GetIt.instance.get<PokeLogger>();
  }
}
