import 'package:flutter/foundation.dart';

enum ServerType { dev, debugServer, staging, prod }

/// Valid options are values defined in [ServerType]
/// Set with `--dart-define=SERVER=staging`
///
/// In our deployment:
/// - [ServerType.prod] is only for TestFlight, AppStore, etc
/// - [ServerType.staging] is for AppCenter
///
/// If none supplied, default is [ServerType.dev] in debug mode
/// and [ServerType.prod] in `--release` (aka [kReleaseMode])
class Server {
  // Note: Only works if const (https://stackoverflow.com/a/71227951/1759443)
  static const String _flavorString = String.fromEnvironment(
    'SERVER',
    defaultValue: kReleaseMode ? 'prod' : 'dev',
  );

  static final ServerType current = _fromString(_flavorString);

  static bool get isProd {
    return current == ServerType.prod;
  }

  static bool get isStaging {
    return current == ServerType.staging;
  }

  static bool get isDebugServer {
    return current == ServerType.debugServer;
  }

  static bool get isLocalhost {
    return current == ServerType.dev;
  }

  static ServerType _fromString(String str) {
    return ServerType.values.firstWhere((e) => e.name == str);
  }
}
