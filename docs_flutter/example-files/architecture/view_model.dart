import 'dart:async';

import 'package:flutter/foundation.dart';

import '../service_locator.dart';
import '../util/logger.dart';
import '../util/stream_subscriber_extensions.dart';
import 'app_lifecycle_observer.dart';

/// Loading: view data is loading - and not available from cache / memory
/// Error: view data failed - and not available from cache / memory
/// Content: We've gotten a view data back and can show it in the UI
enum ViewState { loading, error, content, empty }

abstract class Appearance {
  void onAppear();

  void onDisappear();
}

abstract class ViewModel extends ChangeNotifier implements Appearance {
  /// False if this ViewModel has been disposed
  bool get mounted => _mounted;
  bool _mounted = true;

  /// If this view is currently visible to the user
  bool get isVisible => _isVisible && sl<AppLifecycleObserver>().isForeground;
  bool _isVisible = false;

  /// The list of subscriptions to be disposed. This is a convenience method
  /// to automatically cancel all subscriptions when the view model is disposed.
  ///
  /// Use [subscribe] to add subscriptions to this list.
  List<StreamSubscription> subscriptions = [];

  /// We oftentimes want to do the same thing we do in a constructor
  /// onAppear. Because of this, we'd only want to do it on subsequent appearances.
  /// Example: In the constructor we fetch data. On subsequent appearances we want
  /// to refetch the data. But wouldn't want to fetch the data twice back to back
  /// when first initialized
  bool get subsequentOnAppear => _subsequentOnAppear;
  bool _subsequentOnAppear = false;

  AsyncCallback? get onRefresh => null;

  bool get hasContent => viewState == ViewState.content;

  // Automatically invoked by any subclass
  ViewModel() {
    if (!sl<AppLifecycleObserver>().isForeground) {
      _subsequentOnAppear = true;
    }
  }

  @override
  void notifyListeners() {
    /// ```
    /// await fetch() // long running operation
    /// // ViewModel gets disposed
    /// notifyListeners() // <-- will fail
    /// ```
    // https://stackoverflow.com/a/64842765/1759443
    if (_mounted) {
      return super.notifyListeners();
    }

    log.warn(
      'notifyListeners called on disposed ViewModel. '
      "You've got a leak, buster! Probably from a fetch/mutate call.",
    );
  }

  @mustCallSuper
  @override
  void dispose() {
    log.debug('dispose');
    _mounted = false;
    // When the view model is disposed, it doesn't call onDisappear first
    if (isVisible) {
      onDisappear();
    }
    subscriptions.cancelAll();
    super.dispose();
  }

  Map<String, dynamic> pageViewEventProperties() => {};
  ViewState viewState = ViewState.loading;

  /// Call super on first line
  @mustCallSuper
  @override
  void onAppear() {
    log.debug('onAppear');
    _isVisible = true;
  }

  /// Call super on last line
  @mustCallSuper
  @override
  void onDisappear() {
    _subsequentOnAppear = true;
    _isVisible = false;
    log.debug('onDisappear');
  }

  /// Register the subscription for automatic disposal.
  StreamSubscription<T> subscribe<T>(StreamSubscription<T> subscriber) {
    subscriptions.add(subscriber);
    return subscriber;
  }

  ILogger get log => logger;
}
