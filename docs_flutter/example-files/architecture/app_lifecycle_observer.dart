import 'dart:async';

import 'package:application_state/application_state.dart';
import 'package:flutter/material.dart';

import '../util/logger.dart';

/// Emits when the app is foregrounded or backgrounded via the [stream].
///
/// Also exposes the current state of the app via [isForeground].
/// If the app launches in the background, it will not emit.
/// If the app launches in the foreground, it will emit when ready.
/// You can await [create] to guarantee the value.
class AppLifecycleObserver with WidgetsBindingObserver {
  /// Whether the app is currently foregrounded or not. It defaults to false
  /// when the app is first started and can take a few milliseconds to update.
  bool get isForeground => _isForeground;
  bool _isForeground = false;

  /// Stream that emits updates when status changes
  /// `true` for foreground, `false` for background
  final StreamController<bool> _streamController =
      StreamController<bool>.broadcast();

  Stream<bool> get stream => _streamController.stream;

  AppLifecycleObserver._() {
    WidgetsBinding.instance.addObserver(this);
  }

  static Future<AppLifecycleObserver> create() async {
    final observer = AppLifecycleObserver._();
    await observer._init();
    return observer;
  }

  Future<void> _init() async {
    logger.debug('init');
    final appStatePlugin = ApplicationState();
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      _isForeground = await appStatePlugin.getAppIsForeground();
    } catch (e) {
      _isForeground = false;
    }
    _emitChangeIfNecessary(isForeground: isForeground);

    // appStatePlugin.appIsForegroundStream().listen((isForeground) {
    //   _lifecycleLog.debug('appStatePlugin: $isForeground');
    //   // We redundantly publish this events since they always come in early.
    //   // One might be be slightly before or after but the last thing sent
    //   // _should_ be correct. TODO: is this true?
    //   // We need this one since if `runApp` hasn't been called, there is no
    //   // "WidgetsBinding" to observe (bg case).
    //   _emitChangeIfNecessary(isForeground: isForeground);
    // });
  }

  void _emitChangeIfNecessary({required bool isForeground}) {
    final currentIsForeground = _isForeground;
    _isForeground = isForeground;
    final hasForegroundChanged = currentIsForeground != isForeground;
    if (hasForegroundChanged) {
      logger.debug('Emitting: $isForeground');
      _streamController.add(isForeground);
    }
  }

  @protected
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.debug('didChangeAppLifecycleState: $state');
    final isAppShowing =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    _emitChangeIfNecessary(isForeground: isAppShowing);
  }

  /// In exceptionally rare cases we have an external source that knows
  /// we're foreground before AppLifecycleObserver does. This method allows
  /// us to force the foreground state.
  ///
  /// The only example now is on notification click.
  ///
  /// TODO: check if appStatePlugin covers this.
  void forceSetForeground({
    required bool isForeground,
    required String debugOrigin,
  }) {
    logger.debug('forceSetForeground: $isForeground from $debugOrigin');
    _emitChangeIfNecessary(isForeground: isForeground);
  }
}
