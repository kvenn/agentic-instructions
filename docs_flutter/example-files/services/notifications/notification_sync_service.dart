import 'dart:async';

import '../../../network/api_response.dart';
import '../../../repositories/app_repository_interface.dart';
import '../../../util/logger.dart';
import '../../auth/auth_service_interface.dart';
import 'push_notification_service.dart';

class NotificationSyncService {
  /// Combines AuthService, AppRepository, and PushNotificationService
  /// To handle syncing push notification tokens
  NotificationSyncService(
    Future<AppRepository> appRepositoryFuture,
    Future<PushNotificationService> pushServiceFuture,
    AuthService authService,
  ) {
    unawaited(
      _initPushNotifications(
        appRepositoryFuture,
        pushServiceFuture,
        authService,
      ),
    );
  }

  Future<void> _initPushNotifications(
    Future<AppRepository> appRepositoryFuture,
    Future<PushNotificationService> pushServiceFuture,
    AuthService authService,
  ) async {
    try {
      // Initialize both in parallel
      final (repo, pushService) = await (
        appRepositoryFuture,
        pushServiceFuture,
      ).wait;

      Future<void> setToken() async {
        // Get the initial token and send it to the backend
        final token = await pushService.getToken();
        if (token != null) {
          // Send token to backend
          final response = await repo.updateNotificationToken(token);
          if (response is Failure) {
            logger.error('Failed to send push notification token to backend}');
          } else {
            logger.debug('Push notification token sent to backend');
          }
        }
      }

      if (authService.isLoggedIn()) {
        // User is already logged in, set the token immediately
        await setToken();
      } else {
        // User is not logged in, wait for auth changes
        logger.debug(
          'User not logged in, waiting for auth changes to set token',
        );
      }

      authService.authChangeStream.listen((user) async {
        if (user != null) {
          // User is logged in, send the token
          await setToken();
        } else {
          // TODO: implement
          // User logged out, clear the token
          // try {
          // await repo.clearNotificationToken();
          // logger.debug('Push notification token cleared on logout');
          // } catch (e) {
          // logger.error('Failed to clear push notification token: $e');
          // }
        }
      });

      // Listen for token refreshes and update the backend
      pushService.onTokenRefresh.listen((newToken) async {
        try {
          await repo.updateNotificationToken(newToken);
          logger.debug('Refreshed FCM token sent to backend');
        } catch (e) {
          logger.error('Failed to update refreshed FCM token: $e');
        }
      });
    } catch (e) {
      logger.error('Failed to initialize push notifications: $e');
      // Continue without push notifications
    }
  }
}
