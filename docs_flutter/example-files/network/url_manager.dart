import 'dart:io';

import 'package:flutter/foundation.dart';

import 'server.dart';

abstract class UrlManager {
  String getBaseWebUrl();
  String getGraphQLUrl();
  String getSubscriptionUrl();

  /// WARNING: Only for debugging purposes. Use to force-set base url.
  void setUrlFromFlavor(ServerType flavor);
}

class NetworkUrlManager implements UrlManager {
  // To use your local server from your iPhone (or another client) update "localhost" your IP address
  // `Bash:` ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{ print $2 }'
  // static const _localHost = '192.168.50.170';
  static const _localHost = 'localhost';

  // Web doesn't support `Platform.`
  static final _webLocalUrl = !kIsWeb && Platform.isAndroid
      ? 'http://10.0.2.2:8000'
      : 'http://$_localHost:8080';
  static const _webStagingUrl = 'http://$_localHost:8080';
  static const _webProdUrl = 'https://sesh-api.secretbutthole.com';
  static const _debugServerUrl = 'http://$_localHost:4000';

  static final _localSocketUrl = !kIsWeb && Platform.isAndroid
      ? 'ws://10.0.2.2:8001/graphql'
      : 'ws://$_localHost:8001/graphql';
  static String _convertToSocketUrl(String webUrl) {
    return '${webUrl.replaceFirst('http', 'ws').replaceFirst('-api', '-websocket')}/graphql';
  }

  late String _currentBaseWebUrl;
  late String _currentSocketUrl;

  NetworkUrlManager() {
    // Leaving this commented so it's easier to toggle for local dev
    // _currentBaseUrl = _stagingUrl;
    setUrlFromFlavor(Server.current);
  }

  @override
  String getBaseWebUrl() {
    return _currentBaseWebUrl;
  }

  @override
  String getGraphQLUrl() {
    return '${getBaseWebUrl()}/graphql';
  }

  @override
  String getSubscriptionUrl() {
    return _currentSocketUrl;
  }

  /// WARNING: Only for debugging purposes. Use to force-set base url.
  @override
  void setUrlFromFlavor(ServerType flavor) {
    switch (flavor) {
      case ServerType.dev:
        _currentBaseWebUrl = _webLocalUrl;
        _currentSocketUrl = _localSocketUrl;
      case ServerType.staging:
        _currentBaseWebUrl = _webStagingUrl;
        _currentSocketUrl = _convertToSocketUrl(_webStagingUrl);
      case ServerType.prod:
        _currentBaseWebUrl = _webProdUrl;
        _currentSocketUrl = _convertToSocketUrl(_webProdUrl);
      case ServerType.debugServer:
        _currentBaseWebUrl = _debugServerUrl;
        _currentSocketUrl = _convertToSocketUrl(_debugServerUrl);
    }
  }
}
