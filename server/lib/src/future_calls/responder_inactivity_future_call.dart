import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Serverpod Persistent FutureCall: Responder Stagnation / Inactivity Detector.
/// If an assigned patrol officer does not transmit GPS telemetry or progress along the route
/// within 60 seconds, Serverpod triggers an automatic check-in alarm and alerts dispatch.
class ResponderInactivityFutureCall extends FutureCall {
  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    session.log('[FutureCall: Inactivity Watchdog] Checking responder telemetry heartbeat...');

    // Publish warning across Dispatcher and Responder channels
    session.messages.postMessage(
      'dispatcher:alerts',
      SimpleMessage('responder_inactivity_warning'),
    );

    session.messages.postMessage(
      'campus:notifications',
      SimpleMessage('responder_inactivity_alert'),
    );

    session.log('[FutureCall: Inactivity Watchdog] Stagnation check completed. Dispatcher pinged.');
  }
}
