// ignore: file_names
import 'package:flutter/widgets.dart';

import '../service_locator.dart';
import 'analytics.dart';

class AnalyticsNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    trackEvent(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    if (newRoute != null) {
      trackEvent(newRoute);
    }
  }

  void trackEvent(Route<dynamic> page) {
    final name = page.settings.name;
    if (name == null) {
      return;
    }
    sl<Analytics>().trackRouteView(name);
  }
}
