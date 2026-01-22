import 'package:flutter/foundation.dart';

final ILogger logger = ConsoleLogger();

abstract class ILogger {
  void debug(String message, [Object? error, StackTrace? stackTrace]);
  void info(String message, [Object? error, StackTrace? stackTrace]);
  void warn(String message, [Object? error, StackTrace? stackTrace]);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

class ConsoleLogger implements ILogger {
  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) =>
      logger.debug('[DEBUG] $message');

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) =>
      logger.debug('[INFO] $message');

  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      logger.debug('[WARNING] $message');

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    logger.debug('[ERROR] $message');
    if (error != null) {
      logger.debug('Error: $error');
    }
    if (stackTrace != null) {
      logger.debug('StackTrace: $stackTrace');
    }
  }
}
