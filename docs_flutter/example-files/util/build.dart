import 'package:flutter/foundation.dart';

import '../network/server.dart' show Server;

/// Prod is usually synonymous with release builds (testflight, app store, staging, etc)
/// Running with this flavor means all services are running (Amplitude, DataDog, Sentry, etc)
///
/// Dev is the default for debug builds
/// See [Server] for what URL we're using.
class Build {
  /// Use this instead of `kReleaseMode` to check if we're in prod.
  /// This way we can override easily by build flavor.
  static bool get isProd => kReleaseMode;

  static bool get isDev => kDebugMode;
}
