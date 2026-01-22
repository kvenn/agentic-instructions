import 'package:flutter/cupertino.dart';

/// An [InheritedWidget] that provides lifecycle hooks to their children
/// for the onAppear and onDisappear lifecycle events.
///
/// ```dart
/// final streamProvider = InheritedParentLifecycle.of(context);
/// if (streamProvider != null) {
///  _appearSubscription = streamProvider.appearStream.listen((_) ...
///  _disappearSubscription = streamProvider.disappearStream.listen((_) ...
/// }
/// ```
class InheritedParentLifecycle extends InheritedWidget {
  final Stream<void> appearStream;
  final Stream<void> disappearStream;

  const InheritedParentLifecycle({
    required super.child,
    required this.appearStream,
    required this.disappearStream,
    super.key,
  });

  static InheritedParentLifecycle? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedParentLifecycle>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}
