import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.rsvpGoing,
    required this.rsvpGoingContainer,
    required this.rsvpSub,
    required this.rsvpSubContainer,
    required this.rsvpDeclined,
    required this.rsvpDeclinedContainer,
    required this.warning,
    required this.onWarning,
  });

  final Color rsvpGoing;
  final Color rsvpGoingContainer;
  final Color rsvpSub;
  final Color rsvpSubContainer;
  final Color rsvpDeclined;
  final Color rsvpDeclinedContainer;
  final Color warning;
  final Color onWarning;

  @override
  AppThemeExtension copyWith({
    Color? rsvpGoing,
    Color? rsvpGoingContainer,
    Color? rsvpSub,
    Color? rsvpSubContainer,
    Color? rsvpDeclined,
    Color? rsvpDeclinedContainer,
    Color? warning,
    Color? onWarning,
  }) {
    return AppThemeExtension(
      rsvpGoing: rsvpGoing ?? this.rsvpGoing,
      rsvpGoingContainer: rsvpGoingContainer ?? this.rsvpGoingContainer,
      rsvpSub: rsvpSub ?? this.rsvpSub,
      rsvpSubContainer: rsvpSubContainer ?? this.rsvpSubContainer,
      rsvpDeclined: rsvpDeclined ?? this.rsvpDeclined,
      rsvpDeclinedContainer:
          rsvpDeclinedContainer ?? this.rsvpDeclinedContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
    );
  }

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      rsvpGoing: Color.lerp(rsvpGoing, other.rsvpGoing, t)!,
      rsvpGoingContainer: Color.lerp(
        rsvpGoingContainer,
        other.rsvpGoingContainer,
        t,
      )!,
      rsvpSub: Color.lerp(rsvpSub, other.rsvpSub, t)!,
      rsvpSubContainer: Color.lerp(
        rsvpSubContainer,
        other.rsvpSubContainer,
        t,
      )!,
      rsvpDeclined: Color.lerp(rsvpDeclined, other.rsvpDeclined, t)!,
      rsvpDeclinedContainer: Color.lerp(
        rsvpDeclinedContainer,
        other.rsvpDeclinedContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
    );
  }

  // Light theme colors
  static const _lightTheme = AppThemeExtension(
    rsvpGoing: Colors.green,
    rsvpGoingContainer: Color(0xFFE8F5E8),
    rsvpSub: Colors.orange,
    rsvpSubContainer: Color(0xFFFFF3E0),
    rsvpDeclined: Colors.red,
    rsvpDeclinedContainer: Color(0xFFFFEBEE),
    warning: Colors.orange,
    onWarning: Colors.white,
  );

  // Dark theme colors
  static const _darkTheme = AppThemeExtension(
    rsvpGoing: Color(0xFF4CAF50),
    rsvpGoingContainer: Color(0xFF2E7D32),
    rsvpSub: Color(0xFFFF9800),
    rsvpSubContainer: Color(0xFFE65100),
    rsvpDeclined: Color(0xFFF44336),
    rsvpDeclinedContainer: Color(0xFFD32F2F),
    warning: Color(0xFFFF9800),
    onWarning: Colors.black,
  );

  static AppThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>() ?? _lightTheme;
  }

  static AppThemeExtension light() => _lightTheme;
  static AppThemeExtension dark() => _darkTheme;
}
