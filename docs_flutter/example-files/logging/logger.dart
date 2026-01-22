import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../flavors.dart';
import '../flavors_util.dart';
import '../networking/graphql_provide.dart';
import '../ping/utils/log_record_tracker.dart';
import '../shared/server.dart';
import 'crash_reporting.dart';

/// The general purpose logger for the app.
/// - [Logger.debug] - Verbose logs. Only logged to console in debug mode (or if overridden).
/// - [Logger.info] - Useful information that gets sent to our observability tools (if overridden)
/// - [Logger.warning] - Something that could be a problem. Non-fatal. Always goes to observability on prod.
/// - [Logger.error] - Fatal error that causes significantly degraded UX. Always goes to observability on prod.
///
/// Resources
/// - Use [AppLogger.withName] to create a context-specific logger
/// - See [AppLogger._initAppLogger] for more details on what logs go where.
/// - See [AppLogger._logOverride] for conditions on sending to Sentry/DataDog
///
/// Other global loggers
/// - [graphqlLog]
final String _appLoggerName = F.title;
final Logger logger = Logger(_appLoggerName);

/// kReleaseMode || BuildFlavor.isProd
/// kReleaseMode is true for AppCenter and TestFlight builds
/// BuildFlavor.isProd is for testing prod builds locally
final bool observabilityServicesEnabled = kReleaseMode || BuildFlavor.isProd;

class AppLogger {
  // Minimum duration between the same log being reported repeatedly
  // static const _loggerDebounceDuration = Duration(seconds: 10);

  static bool Function() _currentUserIsStaff = () => false;
  static late LogRecordTracker _logRecordTracker;

  /// Create a logger with a new 'domain'. Provide a 'domain' if you think
  /// it would be helpful to filter by or set specific log rules for.
  ///
  /// Convention: all-lowercase-with-dashes
  ///
  /// It will follow the reporting rules of the app logger _and_ root logger.
  static Logger withName(String name) {
    return Logger('$_appLoggerName.$name');
  }

  /// Sentry must be initialized before this.
  static void init(LogRecordTracker logRecordTracker) {
    _logRecordTracker = logRecordTracker;
    _initRootLogger();
    _initAppLogger();
  }

  /// To reduce dependencies, this can be called whenever (and only needs to be
  /// set once).
  static void setIsStaff(bool Function() isStaffProvider) {
    _currentUserIsStaff = isStaffProvider;
  }

  /// This should run for all logs
  static void _initRootLogger() {
    // This is a global variable declared in the logging package
    hierarchicalLoggingEnabled = true;

    /// We want all logs to be collected at the root for when we
    /// report verbose logs
    Logger.root.level = Level.ALL;
  }

  /// ERROR and WARNING always go to server on release mode.
  /// INFO logs only go to server if [_logOverride] is true.
  static void _initAppLogger() {
    // Only logs of level info or above will be reported to other services
    logger.level = Level.ALL;
    logger.onRecord.listen((logRecord) {
      // All logs (at minimum) always get printed to console on non-prod builds.
      // Format it the way we want to see it in our console
      final message = _formatLogForConsole(logRecord);

      final stackTrace = logRecord.stackTracePlus;
      // It's called error, but we can pass it anything
      final Object? logObject = logRecord.error;

      String objectToAppend = '';

      // If log logRecord.error is instance of LogAttributes, then format it as json
      // and assign new variable with it assigned to message
      if (logObject is LogAttributes) {
        final logObjectJson = logObject.toString();
        final logObjectJsonFormatted = logObjectJson
            .replaceAll('{', '{\n')
            .replaceAll('}', '\n}')
            .replaceAll(',', ',\n');
        objectToAppend = '\n$logObjectJsonFormatted';
      } else if (logObject != null) {
        objectToAppend = '\n$logObject';
      }

      final messageToLog =
          '$message'
          '$objectToAppend'
          '${stackTrace != null ? '\n$stackTrace' : ''}';

      // This will only log on non-prod (if not overridden)
      _logPrint(logRecord.level, messageToLog);

      if (!observabilityServicesEnabled || shouldSuppressLog(logRecord)) {
        return;
      }
      _logRecordTracker.recordReport(logRecord.message);
      _sendLogToSentry(logRecord);
      _sendLogToDataDog(logRecord);
    });
  }

  /// Use this if you want to print to console. Will show in release builds if
  /// [_logOverride] is true.
  static void _logPrint(Level level, String message) {
    if (_logOverride || !BuildFlavor.isProd) {
      if (level.value >= AppLevels.ERROR.value) {
        // Handling multiline messages for errors
        final List<String> lines = message.split('\n');
        // ignore: avoid_print
        lines.forEach(print);

        // This is supposed to turn the logs red
        // This broke showing logs in Terminal so I'm turning it off for now.
        // developer.log('\x1B[31m$line\x1B[0m', name: 'ERROR');
        // print('\x1B[31m$line\x1B[0m');
      } else {
        // Normal color for info and debug
        // We're okay printing to console since user is staff or it's a staging build.
        // ignore: avoid_print
        print(message);
      }
    } else {
      // These don't show up on release builds
      logger.debug(message);
    }
  }

  /// User is staff or this is a staging build
  static bool get _logOverride {
    final bool isStaff = _currentUserIsStaff();
    return isStaff || Server.isStaging;
  }

  /// Send to Datadog as a log
  /// https://docs.datadoghq.com/logs/log_collection/flutter/
  static void _sendLogToDataDog(LogRecord logRecord) {
    final level = logRecord.level;
    final message = logRecord.message;
    final datadogLog = DatadogSdk.instance.logs?.createLogger(
      DatadogLoggerConfiguration(),
    );

    Map<String, Object?> attributes = {};
    final logObject = logRecord.error;
    String? errorMessage;
    if (logObject is LogAttributes) {
      attributes = {
        'loggerName': logRecord.loggerName,
        'extras': {...logObject},
      };
    } else {
      attributes = {'loggerName': logRecord.loggerName};
      errorMessage = logRecord.error?.toString();
      if (errorMessage != null) {
        attributes['errMessage'] = errorMessage;
      }
    }

    final stackTrace = logRecord.stackTracePlus;

    // Map Level to DatadogLogLevel
    if (level == AppLevels.DEBUG) {
      datadogLog?.debug(
        message,
        attributes: attributes,
        errorStackTrace: stackTrace,
        errorMessage: errorMessage,
      );
    } else if (level == Level.INFO || level == AppLevels.LOUD) {
      datadogLog?.info(
        message,
        attributes: attributes,
        errorStackTrace: stackTrace,
        errorMessage: errorMessage,
      );
    } else if (level == Level.WARNING) {
      datadogLog?.warn(
        message,
        attributes: attributes,
        errorStackTrace: stackTrace,
        errorMessage: errorMessage,
      );
      // } else if (level == AppLevels.ERROR) {
      //   datadogLog?.error(
      //     message,
      //     attributes: attributes,
      //     errorStackTrace: stackTrace,
      //     errorMessage: errorMessage,
      //   );
    } else {
      datadogLog?.error(
        message,
        attributes: attributes,
        errorStackTrace: stackTrace,
        errorMessage: errorMessage,
      );
    }
  }

  static void _sendLogToSentry(LogRecord logRecord) {
    if (logRecord.level < AppLevels.ERROR) {
      // Let's not log everything, since that counts against quota.
      return;
    }

    CrashReporting.sentryException(
      logRecord.message,
      level: _levelToSentryLevel(logRecord.level),
      stackTrace: logRecord.stackTracePlus,
      throwable: logRecord.error,
      // `log` lets us pass an error Object which we use to pass extra details
      extra: logRecord.error is LogAttributes
          ? (logRecord.error! as LogAttributes)
          : null,
    );
  }

  /// Map to sentry's levels. They also have [SentryLevel.fatal] which is for
  /// crashes. The error boundary will handle those.
  /// Default to error if we don't have a mapping.
  static SentryLevel _levelToSentryLevel(Level level) {
    if (level == AppLevels.DEBUG) {
      return SentryLevel.debug;
    } else if (level == Level.INFO) {
      return SentryLevel.info;
    } else if (level == Level.WARNING) {
      return SentryLevel.warning;
    } else if (level == AppLevels.ERROR) {
      return SentryLevel.error;
    } else if (level > AppLevels.ERROR) {
      // Uncaught exceptions
      return SentryLevel.fatal;
    }
    return SentryLevel.error;
  }

  /// We suppress certain logs from hitting our logging systems to prevent
  /// exceeding quotas.
  ///
  /// Suppresses:
  /// - Logs below [AppLevels.LOUD] (unless staff or staging)
  /// - Errors and warnings that were reported recently (like in a loop)
  /// - Certain noisy logs that are not actionable
  static bool shouldSuppressLog(LogRecord logRecord) {
    final message = logRecord.message;

    if (!isLogLoudEnough(logRecord)) {
      return true;
    }

    if (wasSameLogReportedRecently(logRecord.level, logRecord.message)) {
      return true;
    }

    // Handshake Network Error Warning
    // https://sodality-tech.sentry.io/issues/4169243387/?project=6235791&query=&sort=freq&statsPeriod=7d&stream_index=0
    if (logRecord.level == Level.WARNING &&
        logRecord.loggerName == 'graphql' &&
        message.startsWith(
          'Request Error (network): ServerException(originalException: HandshakeException',
        )) {
      return true;
    }

    // Sentry has internal check to only send WARNING and above
    // Attempt to quite this very noisy warning - https://sodality-tech.sentry.io/issues/4169243387/?project=6235791&query=is:unresolved&stream_index=0
    if (message.contains('IOClient.send')) {
      return true;
    }

    return false;
  }

  /// Only report logs above(>=) loud (loud, warning, error, etc)
  /// Exception: Overridden (via [_logOverride] - staging and staff)
  /// Returns `true` if the error is loud enough to be reported
  static bool isLogLoudEnough(LogRecord logRecord) {
    return logRecord.level >= AppLevels.LOUD ||
        (_logOverride && logRecord.level >= Level.INFO);
  }

  /// Deduplicate errors and warnings (from blowing out quotas)
  /// Warnings: 1 per day
  /// Errors: 1 per 4 hours
  static bool wasSameLogReportedRecently(Level level, String errorMessage) {
    if (level != Level.WARNING && level != AppLevels.ERROR) {
      // We only deduplicate warnings and errors.
      // Below that should only be sent for staff or staging.
      return false;
    }
    final Duration duration = level == Level.WARNING
        ? const Duration(days: 1)
        : const Duration(hours: 4);
    return _logRecordTracker.reportedWithin(errorMessage, duration);
  }

  static String _formatLogForConsole(LogRecord log) {
    try {
      final String levelFirstLetter = log.level.name.isNotEmpty
          ? log.level.name[0]
          : '';
      final String time = _formatTime(log.time);
      final String logNameString = _formatLoggerName(log.loggerName);

      return '[$levelFirstLetter][$time]$logNameString: ${log.message}';
    } catch (_) {
      // If formatting fails, print raw log as a fallback
      return log.toString();
    }
  }

  static String _formatTime(DateTime logTime) {
    try {
      // Format date minified in format: M-d HH:mm:ss.SSS
      return DateFormat('M-d HH:mm:ss.SSS').format(logTime);
    } catch (_) {
      // If DateFormat fails, printing raw time string as a fallback
      return logTime.toString();
    }
  }

  static String _formatLoggerName(String loggerName) {
    // Break logger name into components and format accordingly
    final List<String> nameComponents = loggerName.split('.');
    // Remove the first part if it is equal to predefined app logger name
    if (nameComponents.isNotEmpty && nameComponents.first == _appLoggerName) {
      nameComponents.removeAt(0);
    }

    if (nameComponents.isEmpty) {
      return '';
    }

    // Format for readability:
    // Single name results in "[name]", multiple in "[name1][name2][...]"
    return nameComponents.length >= 2
        ? '[${nameComponents.join('][')}]'
        : '[${nameComponents.single}]';
  }
}

typedef LogAttributes = Map<String, dynamic>;

/// Most platforms support: debug (600), info (800), warning (900) and error (1000).
/// INFO and WARNING already exist. We're adding DEBUG and ERROR.
extension AppLevels on Level {
  // ignore: constant_identifier_names
  static const Level DEBUG = Level('DEBUG', 600);
  // ignore: constant_identifier_names
  static const Level ERROR = Level('ERROR', 1000);
  // Loud is for info we want to show even for non _logOverride users
  // ignore: constant_identifier_names
  static const Level LOUD = Level('LOUD', 850);
}

/// Helpers for the log levels we defined
extension AppLoggers on Logger {
  /// Used for info logs we should keep for all users on prod.
  void loud(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(AppLevels.LOUD, message, error, stackTrace);

  /// Used for verbose logging. These won't go to Sentry or DataDog.
  void debug(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(AppLevels.DEBUG, message, error, stackTrace);

  /// [message] can be a [String] or [Exception] object. Internally [log]
  /// will call [toString] on it.
  ///
  /// If [message] is an [Exception], [error] will be ignored.
  ///
  /// [stackTrace] is optional. If not provided, it will use the current stack trace.
  void error(Object? message, [Object? error, StackTrace? stackTrace]) {
    log(
      AppLevels.ERROR,
      message,
      message is Exception ? message : error,
      stackTrace,
    );
  }
}

/// Send verbose logs for each navigation
class LogNavigationChanges extends NavigatorObserver {
  final _log = AppLogger.withName('navigation');

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.debug(
      'Pushed from ${previousRoute?.settings.name} to ${route.settings.name}',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log.debug(
      'Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log.debug(
      'Popped ${route.settings.name} to ${previousRoute?.settings.name}',
    );
  }
}

extension CleanerStackTrace on LogRecord {
  StackTrace? get stackTracePlus {
    // Don't bother with stack traces for lower levels of logs
    if (level < Level.WARNING) {
      return null;
    }

    if (stackTrace != null) {
      return stackTrace;
    }

    final fError = error;
    StackTrace? errorStackTrace;
    if (fError != null && fError is Error) {
      errorStackTrace = fError.stackTrace;
    }

    return errorStackTrace ?? CrashReporting.currentStackTrace();
  }
}
