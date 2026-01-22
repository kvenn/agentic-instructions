import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../util/logger.dart';

enum NotificationEvent { launch, background, foreground }

class PushNotificationService {
  final Future<FirebaseApp> _firebaseFuture;
  final FirebaseMessaging _messaging;
  final Function(Map<String, dynamic> data, {required NotificationEvent event})
  _handleNotification;

  /// Cached FCM token
  String? _token;

  /// Stream controller for token refresh events
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  /// Stream of token refresh events
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  PushNotificationService(
    this._firebaseFuture,
    this._messaging,
    this._handleNotification,
  );

  Future<void> init() async {
    try {
      await _firebaseFuture;
      // Request permission
      final settings = await _messaging.requestPermission();
      logger.debug(
        'Notification permission status: ${settings.authorizationStatus}',
      );
      // Get the initial token
      _token = await _getToken();

      // Set up token refresh listener
      _messaging.onTokenRefresh.listen((newToken) {
        logger.debug('FCM token refreshed: $newToken');
        _token = newToken;

        // Add the new token to the stream
        _tokenRefreshController.add(newToken);
      });

      // Handle cold start (app was terminated)
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        logger.debug('Handling initial notification with eventId: $initial');
        _handleNotification(initial.data, event: NotificationEvent.launch);
      }

      // Handle taps when app is backgrounded/foregrounded
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        logger.debug(
          'Handling background notification tap with eventId: $message',
        );
        _handleNotification(message.data, event: NotificationEvent.background);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logger.debug('Got a message whilst in the foreground!');
        logger.debug('Message data: ${message.data}');

        if (message.notification != null) {
          logger.debug(
            'Message also contained a notification: ${message.notification}',
          );
          // Here you would show a local notification
          // This would typically use flutter_local_notifications
        }
      });
    } catch (e) {
      logger.error('Error initializing push notifications: $e');
      // Continue without push notifications in development
    }
  }

  /// Get the current FCM token
  ///
  /// Returns the cached token if available, otherwise fetches a new one
  Future<String?> getToken() async {
    try {
      if (_token != null) {
        return _token;
      }

      // Get a new token
      return _token = await _getToken();
    } catch (e) {
      logger.error('Error getting FCM token: $e');
      return null;
    }
  }

  /// Dispose of resources
  void dispose() {
    _tokenRefreshController.close();
  }

  Future<String?> _getToken() async {
    try {
      // Ensure Firebase is initialized
      await _firebaseFuture;
      // Allow time for Firebase to initialize
      // await Future.delayed(const Duration(seconds: 1));
      // final token = await _messaging.getAPNSToken();
      final token = await _messaging.getToken();
      logger.debug('FCM Token: $token');
      return token;
    } catch (e) {
      logger.error('Error getting FCM token: $e');
      return null;
    }
  }
}
