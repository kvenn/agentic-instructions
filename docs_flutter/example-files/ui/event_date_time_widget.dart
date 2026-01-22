import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDateTimeWidget extends StatelessWidget {
  final DateTime dateTime;
  final double? fontSize;
  final bool showIcon;

  const EventDateTimeWidget({
    required this.dateTime,
    this.fontSize,
    this.showIcon = true,
    super.key,
  });

  /// Create from ISO string (like from GraphQL)
  factory EventDateTimeWidget.fromIsoString(
    String isoString, {
    double? fontSize,
    bool showIcon = true,
  }) {
    return EventDateTimeWidget(
      dateTime: DateTime.parse(isoString).toLocal(),
      fontSize: fontSize,
      showIcon: showIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('E, MMM d • h:mm a');
    final formattedDate = dateFormat.format(dateTime);

    final textStyle = fontSize != null
        ? theme.textTheme.bodyMedium?.copyWith(fontSize: fontSize)
        : theme.textTheme.bodyMedium;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            formattedDate,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
