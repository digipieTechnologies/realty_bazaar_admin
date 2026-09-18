// File: lib/models/notification_enums.dart
// Purpose: Strictly scoped NotificationType enum (video_request, lead).

enum NotificationType {
  videoRequest('video_request'),
  lead('lead'),
  launchProperty('launch_property');

  final String dbValue;

  const NotificationType(this.dbValue);

  static NotificationType fromDbValue(String? value) {
    switch (value) {
      case 'video_request':
        return NotificationType.videoRequest;
      case 'launch_property':
        return NotificationType.launchProperty;
      case 'lead':
      default:
        return NotificationType.lead;
    }
  }
}
