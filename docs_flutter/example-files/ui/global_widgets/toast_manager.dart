import 'package:flutter/material.dart';

import '../build_context_extensions.dart';

/// All the same functionality as snackbar
abstract interface class ToastManager {
  /// Shows a toast message with the given [message].
  void show(String message, {Duration? duration, ToastAction? action});

  /// Shows a warning toast message with the given [message].
  void showWarning(String message, {Duration? duration, ToastAction? action});

  /// Shows an error toast message with the given [message].
  void showError(String message, {Duration? duration, ToastAction? action});

  /// Call this in the circumstance where you have nested contexts
  void updateContext(BuildContext context);

  /// Hides the currently displayed toast message, if any.
  void hide();
}

class ToastAction {
  final String label;
  final VoidCallback? onPressed;

  ToastAction({required this.label, this.onPressed});
}

/// A class for showing toast messages in the app. It uses the Snackbar
class SnackbarToastManager implements ToastManager {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  BuildContext? _context;

  @override
  void updateContext(BuildContext context) {
    _context = context;
  }

  @override
  void show(String message, {Duration? duration, ToastAction? action}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(seconds: 3),
      action: action != null
          ? SnackBarAction(
              label: action.label,
              onPressed: action.onPressed ?? hide,
            )
          : null,
    );

    _showSnackbar(snackBar);
  }

  @override
  void showWarning(String message, {Duration? duration, ToastAction? action}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: _context?.appColors.warning ?? Colors.orange,
      // behavior: SnackBarBehavior.floating,
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      action: action != null
          ? SnackBarAction(
              label: action.label,
              textColor: _context?.appColors.onWarning ?? Colors.white,
              onPressed: action.onPressed ?? hide,
            )
          : null,
    );

    _showSnackbar(snackBar);
  }

  @override
  void showError(String message, {Duration? duration, ToastAction? action}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: _context?.colors.error ?? Colors.red,
      // behavior: SnackBarBehavior.floating,
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      action: action != null
          ? SnackBarAction(
              label: action.label,
              textColor: _context?.colors.onError ?? Colors.white,
              onPressed: action.onPressed ?? hide,
            )
          : null,
    );

    _showSnackbar(snackBar);
  }

  @override
  void hide() {
    final context = _context;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else {
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    }
  }

  void _showSnackbar(SnackBar snackBar) {
    // ScaffoldMessenger.of(context).showSnackBar(snackBar);
    // snackbarKey.currentState?.showSnackBar(snackBar);

    // We have two options for showing a snackbar. If the context is valid / current, we use it directly.
    // Otherwise we use the scaffold messenger key to show the snackbar.
    final context = _context;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(snackBar);
    } else {
      scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
    }
  }
}
