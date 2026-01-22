import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../util/logger.dart';

class CrashReporting {
  final Future<FirebaseApp> _firebaseFuture;

  CrashReporting(Future<FirebaseApp> firebaseApp)
    : _firebaseFuture = firebaseApp;

  Future<void> init({String? sentryDsn}) async {
    initFirebase();

    try {
      await SentryFlutter.init((options) {
        if (sentryDsn != null) options.dsn = sentryDsn;
      });
      logger.debug('Sentry initialized');
    } catch (e) {
      logger.error('Failed to initialize Sentry: $e');
      // Continue without Sentry in development
    }
  }

  void initFirebase() {
    _firebaseFuture.then(
      (app) =>
          FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true),
    );
  }

  void log(String message) {
    try {
      Sentry.captureMessage(message);
    } catch (e) {
      logger.error('Failed to log to Sentry: $e');
    }

    try {
      _firebaseFuture.then((app) => FirebaseCrashlytics.instance.log(message));
    } catch (e) {
      logger.error('Failed to log to Crashlytics: $e');
    }
  }

  void recordErrorDetails(FlutterErrorDetails details) {
    try {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    } catch (e) {
      logger.error('Failed to record Flutter error to Sentry: $e');
    }

    try {
      _firebaseFuture.then((app) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      });
    } catch (e) {
      logger.error('Failed to record Flutter error to Crashlytics: $e');
    }
  }

  void recordError(dynamic exception, StackTrace stackTrace, {String? reason}) {
    try {
      Sentry.captureException(exception, stackTrace: stackTrace);
    } catch (e) {
      logger.error('Failed to record error to Sentry: $e');
    }

    try {
      _firebaseFuture.then((app) {
        FirebaseCrashlytics.instance.recordError(
          exception,
          stackTrace,
          reason: reason,
          fatal: true,
        );
      });
    } catch (e) {
      logger.error('Failed to record error to Crashlytics: $e');
    }
  }
}
