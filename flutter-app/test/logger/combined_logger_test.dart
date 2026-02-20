import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:poke/logger/combined_logger.dart';
import 'package:poke/logger/in_memory_logger.dart';
import 'package:poke/logger/poke_logger.dart';

void main() {
  test('logs messages to all loggers', () {
    final logger1 = PokeInMemoryLogger();
    final logger2 = PokeInMemoryLogger();
    final combinedLogger = CombinedLogger([logger1, logger2]);

    combinedLogger.info('test message');

    expect(
      logger1.messages,
      contains(PokeLogEntry(Level.info, 'test message')),
    );
    expect(
      logger2.messages,
      contains(PokeLogEntry(Level.info, 'test message')),
    );
  });

  test('logs each message only once per logger', () {
    final logger1 = PokeInMemoryLogger();
    final logger2 = PokeInMemoryLogger();
    final combinedLogger = CombinedLogger([logger1, logger2]);

    combinedLogger.info('test message');

    expect(logger1.messages, hasLength(1));
    expect(logger2.messages, hasLength(1));
  });
}
