import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:focus_detector/focus_detector.dart';

import '../../service_locator.dart';
import '../../shared/app_lifecycle_observer.dart';
import '../../shared/architecture/inherited_parent_lifecycle.dart';
import '../../shared/architecture/view_model.dart';

/// A convenience wrapper to get events via callback for:
/// - When the widget is first inserted into the tree
/// - When the widget becomes visible or enters foreground while visible
/// - When the widget becomes invisible or enters background while visible
/// - When the widget is disposed
///
/// If a child needs a parent's events, see [InheritedParentLifecycle].
class LifecycleWidget extends StatefulWidget {
  const LifecycleWidget({
    required this.child,
    this.onInit,
    this.onAppear,
    this.onDisappear,
    this.viewModel,
    super.key,
  });

  /// Called when this object is first inserted into the tree.
  final VoidCallback? onInit;

  /// Called when the widget becomes visible or enters foreground while visible.
  final VoidCallback? onAppear;

  /// Called when the widget becomes invisible or enters background while visible.
  /// NOTE: This gets fired after onDispose in many instances (when the widget
  /// is removed from the tree).
  final VoidCallback? onDisappear;

  /// Optional view model to call through to. Usually used instead of
  /// [onAppear] and [onDisappear], but you can use both.
  final ViewModel? viewModel;

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _LifecycleWidgetState createState() => _LifecycleWidgetState();
}

class _LifecycleWidgetState extends State<LifecycleWidget> {
  final _appearStreamController = StreamController<void>.broadcast();
  final _disappearStreamController = StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      widget.onInit?.call();
    });
  }

  bool _isForeground = false;
  bool _isFocused = false;
  bool _isShowing = false;

  /// We only want to trigger onAppear if
  /// - The app is in the foreground
  /// - The widget is focused (appeared)
  /// - We didn't already trigger an onAppear
  ///
  /// This is necessary because onAppear can get called when the app isn't
  /// in the foreground. So onAppForeground should trigger onAppear
  /// This state comes from [AppLifecycleObserver].
  ///
  /// Returns `true` if onAppear was triggered
  bool onAppear() {
    if (_isForeground && _isFocused && !_isShowing) {
      _isShowing = true;
      widget.onAppear?.call();
      widget.viewModel?.onAppear();

      // Emit event through appearStream
      _appearStreamController.add(null);
      return true;
    }
    return false;
  }

  bool firstBuildFired = false;
  @override
  Widget build(BuildContext context) {
    // Stream builder that subscribes to appCycleState.stream
    return InheritedParentLifecycle(
      appearStream: _appearStreamController.stream,
      disappearStream: _disappearStreamController.stream,
      child: StreamBuilder<bool>(
        stream: sl<AppLifecycleObserver>().stream,
        initialData: sl<AppLifecycleObserver>().isForeground,
        builder: (_, snapshot) {
          _isForeground = snapshot.data ?? false;
          // This build was triggered. Set state so we don't fire two
          // onAppear events
          // We fire this at all because FocusDetector can be delayed for
          // the first build and also doesn't cover foregrounds
          firstBuildFired = onAppear();
          return FocusDetector(
            onFocusGained: () {
              _isFocused = true;
              if (firstBuildFired == false) {
                onAppear();
              } else {
                firstBuildFired = false;
              }
            },
            onFocusLost: () {
              _isShowing = false;
              _isFocused = false;
              widget.onDisappear?.call();
              if (widget.viewModel?.mounted ?? false) {
                // TODO: Disappear is triggered after dispose, but this
                //  means when leaving a page, disappear isn't triggered
                //  sometimes (since no longer mounted)
                widget.viewModel?.onDisappear();
              }
              if (_disappearStreamController.isClosed == false) {
                _disappearStreamController.add(null);
              }
            },
            child: widget.child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _appearStreamController.close();
    _disappearStreamController.close();
    super.dispose();
  }
}
