import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/create_event/create_event_page.dart';
import '../../../../features/event_detail/event_detail_page.dart';
import '../../../../features/events/events_list_page.dart';
import '../../../../features/onboarding/onboarding_page.dart';
import '../../../../graphql/fragments.graphql.dart';
import '../../../../util/logger.dart';
import '../../../auth/auth_service_interface.dart';

class AppRouter {
  // Route names
  static const routeOnboarding = 'onboarding';
  static const routeEventsList = 'events_list';
  static const routeEventDetail = 'event_detail';
  static const routeCreateEvent = 'create_event';
  static const routeEditEvent = 'edit_event';
  static const routeProfile = 'profile';

  // Param keys
  static const paramEventId = 'eventId';

  final GoRouter router;

  AppRouter(AuthService authService)
    : router = GoRouter(
        initialLocation: authService.isLoggedIn() ? '/' : '/$routeOnboarding',
        routes: [
          GoRoute(
            name: routeOnboarding,
            path: '/$routeOnboarding',
            builder: (_, __) => const OnboardingPage(),
          ),
          GoRoute(
            name: routeEventsList,
            path: '/',
            builder: (_, __) => const EventsListPage(),
            routes: [
              GoRoute(
                name: routeEventDetail,
                path: '/events/:$paramEventId',
                builder: (context, state) {
                  final id = state.pathParameters[paramEventId]!;
                  return EventDetailPage(eventId: id);
                },
              ),
              GoRoute(
                name: routeCreateEvent,
                path: '/$routeCreateEvent',
                builder: (_, __) => const CreateEventPage(),
              ),
              GoRoute(
                name: routeEditEvent,
                path: '/events/:$paramEventId/edit',
                builder: (context, state) {
                  final eventId = state.pathParameters[paramEventId];
                  final eventToEdit = state.extra as Fragment$Event?;

                  if (eventToEdit == null) {
                    logger.warn(
                      'Event data missing for edit. EventId: $eventId',
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        context.go('/');
                      }
                    });
                    return const Scaffold(
                      body: Center(
                        child: Text('Missing event data, redirecting...'),
                      ),
                    );
                  }

                  return CreateEventPage(eventToEdit: eventToEdit);
                },
              ),
              GoRoute(
                name: routeProfile,
                path: '/$routeProfile',
                builder: (_, __) => Scaffold(
                  appBar: AppBar(title: const Text('Profile')),
                  body: const Center(child: Text('Profile page coming soon')),
                ),
              ),
            ],
          ),
        ],
        redirect: (context, state) {
          // Get the current auth status
          final isLoggedIn = authService.isLoggedIn();
          final isOnboardingRoute =
              state.matchedLocation == '/$routeOnboarding';

          // If not logged in and not on onboarding, redirect to onboarding
          if (!isLoggedIn && !isOnboardingRoute) {
            logger.debug('Not logged in, redirecting to onboarding');
            return '/$routeOnboarding';
          }

          // If logged in and on onboarding, redirect to home
          if (isLoggedIn && isOnboardingRoute) {
            logger.debug('Already logged in, redirecting to home');
            return '/';
          }

          // No redirect needed
          return null;
        },
        debugLogDiagnostics: true,
      );
}
