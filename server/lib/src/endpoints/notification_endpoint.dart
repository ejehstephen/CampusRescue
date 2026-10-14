import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Serverpod Real-time Notification & Audio Alert Endpoint
/// Manages high-priority sound chimes, emergency broadcast banners, and security dispatch alerts.
class NotificationEndpoint extends Endpoint {
  static const String channelNotifications = 'campus:notifications';

  /// Broadcast a campus-wide or scoped emergency alert
  Future<void> sendEmergencyAlert(
    Session session, {
    required String title,
    required String message,
    required String priority, // high, medium, low
    String? targetZone,
  }) async {
    session.log('[Serverpod Notification] Alert "$title" sent to zone ${targetZone ?? "ALL"} ($priority priority)');

    session.messages.postMessage(
      channelNotifications,
      SimpleMessage('emergency_alert_sent'),
    );
  }
}

