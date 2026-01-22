import 'package:go_router/go_router.dart';

import '../../../../graphql/fragments.graphql.dart';
import 'app_router.dart';
import 'navigation_service.dart';

class NavigationServiceImpl implements NavigationService {
  final AppRouter _appRouter;
  GoRouter get _router => _appRouter.router;

  NavigationServiceImpl(this._appRouter);

  @override
  void goToOnboarding() => _router.goNamed(AppRouter.routeOnboarding);

  @override
  void goToEventsList() => _router.goNamed(AppRouter.routeEventsList);

  @override
  void pushToEventDetail(String eventId) => _router.pushNamed(
    AppRouter.routeEventDetail,
    pathParameters: {AppRouter.paramEventId: eventId},
  );

  /// Use goNamed instead of pop+push to animate only the transition to event detail
  /// This replaces the current screen in the navigation stack
  @override
  void goToEventDetail(String eventId) {
    _router.goNamed(
      AppRouter.routeEventDetail,
      pathParameters: {AppRouter.paramEventId: eventId},
    );
  }

  @override
  void pushToCreateEvent() => _router.pushNamed(AppRouter.routeCreateEvent);

  @override
  void goToEditEvent(Fragment$Event event) => _router.pushNamed(
    AppRouter.routeEditEvent,
    pathParameters: {AppRouter.paramEventId: event.id},
    extra: event,
  );

  @override
  void goToProfile() => _router.pushNamed(AppRouter.routeProfile);

  @override
  void goBack() => _router.pop();
}
