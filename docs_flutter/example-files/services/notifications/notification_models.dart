// lib/models/notification_models.dart

abstract class NotificationData {
  final String type;
  final String? deeplinkPath;
  NotificationData(this.type, {this.deeplinkPath});

  /// Dispatch to concrete subtype based on `type`
  factory NotificationData.fromMap(Map<String, dynamic> map) {
    switch (map['type'] as String?) {
      case 'new_event':
        return NewEventNotificationData.fromMap(map);
      case 'rsvp_update':
        return RsvpUpdateNotificationData.fromMap(map);
      // add more cases here
      default:
        return UnknownNotificationData(map['type'] as String? ?? 'unknown');
    }
  }
}

class BaseEventNotificationData extends NotificationData {
  final String eventId;
  final String groupId;

  BaseEventNotificationData({
    required String type,
    required this.eventId,
    required this.groupId,
  }) : super(type);
}

class NewEventNotificationData extends BaseEventNotificationData {
  final DateTime startTime;

  NewEventNotificationData({
    required super.eventId,
    required super.groupId,
    required this.startTime,
  }) : super(type: 'new_event');

  factory NewEventNotificationData.fromMap(Map<String, dynamic> map) {
    return NewEventNotificationData(
      eventId: map['eventId'] as String,
      groupId: map['groupId'] as String,
      startTime: DateTime.parse(map['startTime'] as String).toLocal(),
    );
  }
}

class RsvpUpdateNotificationData extends BaseEventNotificationData {
  final DateTime startTime;
  final String status;
  final String userId;

  RsvpUpdateNotificationData({
    required super.eventId,
    required super.groupId,
    required this.startTime,
    required this.status,
    required this.userId,
  }) : super(type: 'rsvp_update');

  factory RsvpUpdateNotificationData.fromMap(Map<String, dynamic> map) {
    return RsvpUpdateNotificationData(
      eventId: map['eventId'] as String,
      groupId: map['groupId'] as String,
      startTime: DateTime.parse(map['startTime'] as String).toLocal(),
      status: map['status'] as String,
      userId: map['userId'] as String,
    );
  }
}

class UnknownNotificationData extends NotificationData {
  UnknownNotificationData(super.type);
}
