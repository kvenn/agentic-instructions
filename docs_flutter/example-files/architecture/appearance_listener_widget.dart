import 'dart:async';

import 'package:flutter/widgets.dart';

import 'inherited_parent_lifecycle.dart';
import 'view_model.dart';

/// If you ever need a ChangeNotifierProvider that isn't supported by
/// `VmBuilder`, you can wrap it with this widget.
///
/// If you ever have a stateful widget that you want to add listening
/// functionality to, you can use [AppearanceListenerWidget].
class AppearanceListenerWidget<AppearanceT extends Appearance>
    extends StatefulWidget {
  final AppearanceT viewModel;
  final Widget Function(BuildContext, AppearanceT, Widget?) builder;
  final Widget? child;

  const AppearanceListenerWidget({
    required this.viewModel,
    required this.builder,
    super.key,
    this.child,
  });

  @override
  _AppearanceListenerWidgetState<AppearanceT> createState() =>
      _AppearanceListenerWidgetState<AppearanceT>();
}

class _AppearanceListenerWidgetState<ViewModelT extends Appearance>
    extends State<AppearanceListenerWidget<ViewModelT>>
    with AppearSubscriptionMixin<AppearanceListenerWidget<ViewModelT>> {
  @override
  void onAppear() {
    widget.viewModel.onAppear();
  }

  @override
  void onDisappear() {
    widget.viewModel.onDisappear();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.viewModel, widget.child);
  }
}

mixin AppearSubscriptionMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<void>? _appearSubscription;
  StreamSubscription<void>? _disappearSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        // The widget can technically unmount in this time period. If state
        // isn't mounted, the call to `context` fails.
        return;
      }
      final streamProvider = InheritedParentLifecycle.of(context);

      if (streamProvider == null) {
        return;
      }
      // Subscribe to appearStream if available
      _appearSubscription = streamProvider.appearStream.listen((_) {
        onAppear();
      });

      // Subscribe to disappearStream if available
      _disappearSubscription = streamProvider.disappearStream.listen((_) {
        onDisappear();
      });
    });
  }

  @override
  void dispose() {
    _appearSubscription?.cancel();
    _disappearSubscription?.cancel();
    super.dispose();
  }

  void onAppear();
  void onDisappear();
}
