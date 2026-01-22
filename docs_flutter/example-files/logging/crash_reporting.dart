import 'package:datadog_flutter_plugin/datadog_flutter_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../components/error_widget.dart';
import '../flavors_util.dart';
import '../logging/performance_tracer_collector.dart';
import '../service_locator.dart';
import '../shared/env_keys.dart';
import '../shared/server.dart';
import 'logger.dart';
import 'performance_trace.dart';

/// Initialize with something like this:
/// ```
///   sl.registerSingletonAsyncWithTracer<CrashReportingShell>(
///   () async {
///     final crashReportingShell = CrashReportingShell();
///     await Future.wait([
///       CrashReporting.initDatadog(),
///       CrashReporting.initSentry(),
///       // If a crash occurs, it logs to the logger
//       CrashReporting.setupErrorHandlers(),
//     ]);
//     return crashReportingShell;
//   },
// );
// ```
class CrashReporting {
  /// `env` is set based on what backend we're hitting ([Server], not [BuildFlavor]).
  /// This is so we can differentiate AppCenter (staging) builds.
  static Future<void> initDatadog() async {
    // TODO: symbols for stacktrace: https://docs.datadoghq.com/real_user_monitoring/error_tracking/flutter/#upload-symbol-files-to-datadog
    final PerformanceTrace datadogTrace = sl<PerformanceTracerCollector>()
        .addTracer('datadog');
    final datadogToken = EnvKeys.datadogToken;
    final datadogAppId = EnvKeys.datadogAppId;
    if (observabilityServicesEnabled &&
        datadogToken != null &&
        datadogAppId != null) {
      final datadogSDKConfig = DatadogConfiguration(
        clientToken: datadogToken,
        env: Server.isProd
            ? 'prod'
            : Server.isStaging
            ? 'staging'
            : 'dev',
        site: DatadogSite.us1,
        nativeCrashReportEnabled: true,
        loggingConfiguration: DatadogLoggingConfiguration(),
        // RUM is pretty expensive...lets turn that off for now.
        // There are other commented out RUM features on this commit.
        // rumConfiguration: RumConfiguration(
        //   applicationId: datadogAppId,
        // ),
      );
      await DatadogSdk.instance.initialize(
        datadogSDKConfig,
        TrackingConsent.granted,
      );
    }
    datadogTrace.stop();
  }

  static Future<void> initSentry() async {
    final PerformanceTrace sentryTrace = sl<PerformanceTracerCollector>()
        .addTracer('sentry');
    await SentryFlutter.init((options) {
      options.beforeSend = (SentryEvent event, _) {
        if (event.level == SentryLevel.error ||
            event.level == SentryLevel.fatal) {
          return event;
        }
        // Filter these message out from sentry
        if (event.message?.formatted.contains('IOClient.send') ?? false) {
          return null;
        }
        return event;
      }; // Keep Sentry off in debug
      options.dsn = EnvKeys.sentryDsn;
      // options.debug = !Flavor.isProd; // Prints exceptions to console
      options.enablePrintBreadcrumbs = false;
    });
    sentryTrace.stop();
  }

  /// This sets up the error handlers. We combine this with onZoneError handler.
  /// There are other options outlined in the docs.
  ///
  /// [Master doc](https://docs.flutter.dev/testing/errors)
  /// [Firebase Docs](https://firebase.google.com/docs/crashlytics/get-started?platform=flutter#configure-crash-handlers)
  /// [Comparison of options](https://stackoverflow.com/questions/75110477/platformdispatcher-instance-onerror-vs-runzonedguarded)
  static Future<void> setupErrorHandlers() async {
    final originalOnError = FlutterError.onError;

    // Catch all errors that are thrown within the Flutter framework
    FlutterError.onError = (details) async {
      FlutterError.presentError(details);

      logger.severe(
        'Uncaught Flutter Error: ${details.exception}',
        details.exception,
        details.stack ?? currentStackTrace(),
      );
      // DatadogSdk.instance.rum?.handleFlutterError(details);
      // await Sentry.captureException(
      //   details.exception,
      //   stackTrace: details.stack,
      // );

      originalOnError?.call(details);
    };

    // The comparison doc above mentions onZoneError as safer. So we're doing that for now.
    // Firebase says to do it with PlatformDispatcher.

    // // Catch all uncaught asynchronous errors that aren't handled by the Flutter framework
    // PlatformDispatcher.instance.onError = (error, stack) {
    //   // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    //   return true;
    // };
  }

  static Future<void> setupErrorWidget() async {
    /// When an error occurs during the build phase,
    /// the ErrorWidget.builder callback is invoked
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // In debug builds show red screen with details
      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }
      logger.error(
        'ErrorWidget shown: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );

      return const RllyErrorWidget();
    };
  }

  /// Wrap your runApp in `await runZonedGuarded` and pass this as the error handler
  static Future<void> onZoneError(Object error, StackTrace stack) async {
    // DatadogSdk.instance.rum?.addErrorInfo(
    //   error.toString(),
    //   RumErrorSource.source,
    //   stackTrace: stack,
    // );
    // await Sentry.captureException(error, stackTrace: stack);
    logger.severe('Uncaught Platform Error: $error', error, stack);
  }

  /// [message] is the prefix that is used for grouping.
  /// [value] is the suffix appended to the message for more granular details.
  static Future<void> sentryException(
    String message, {
    String? value,
    SentryLevel? level,
    StackTrace? stackTrace,
    dynamic throwable,
    Map<String, dynamic>? extra,
  }) async {
    await Sentry.captureEvent(
      SentryEvent(
        message: SentryMessage(
          message + (value != null ? ': $value' : ''),
          template: message,
        ),
        throwable: throwable,
        level: level ?? SentryLevel.error,
        extra: extra,
      ),
      stackTrace: stackTrace ?? currentStackTrace(),
    );
  }

  /// [userMap] will overwrite/set _only_ the attributes included in the map.
  /// If a property is omitted, the previously set value will be retained.
  ///
  /// No-ops if map is empty. You'd need to explicitly set all values to null.
  static void setDataDogUser(Map<String, Object> userMap) {
    if (userMap.isEmpty) {
      return;
    }
    // At minimum, this log should always have user.id on it
    // Matches the way we send on the backend
    for (final entry in userMap.entries) {
      // Datadog respects dot-notation. Without it, we'd overwrite the entire
      // user each time.
      _addDataDogAttribute(name: 'user.${entry.key}', value: entry.value);
    }
  }

  static void _addDataDogAttribute({
    required String name,
    required Object value,
  }) {
    DatadogSdk.instance.logs?.addAttribute(name, value);
  }

  static StackTrace currentStackTrace() {
    final List<String> filteredLines = StackTrace.current
        .toString()
        .split('\n')
        .where(
          (line) =>
              !line.contains('logger.dart') &&
              !line.contains('crash_reporting.dart'),
        )
        .toList();

    return StackTrace.fromString(filteredLines.join('\n'));
  }
}
