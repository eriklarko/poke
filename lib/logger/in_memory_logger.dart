// Used to test logging

import 'dart:async';

import 'package:logger/src/log_level.dart';
import 'package:poke/logger/poke_logger.dart';

class PokeInMemoryLogger extends PokeLogger {
  final List<PokeLogEntry> _logs = [];

  List<PokeLogEntry> get messages {
    return List.unmodifiable(_logs);
  }

  void clear() {
    _logs.clear();
  }

  @override
  FutureOr<void> logAppForegrounded() {
    return info('App foregrounded');
  }

  @override
  FutureOr<void> doLog(Level level, PokeLogEntry log) {
    _logs.add(log);
    return null;
  }
}
