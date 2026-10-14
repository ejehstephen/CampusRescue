import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class IncidentEndpoint extends Endpoint {
  static const String channelCampusEmergency = 'campus:emergency';
  static const String channelDispatcherAlerts = 'dispatcher:alerts';

  // Handle student SOS distress beacon
  Future<Map<String, dynamic>> reportSosIncident(
    Session session, {
    required String category,
    required String description,
    required String campusZone,
    String? roomNumber,
    required double latitude,
    required double longitude,
    required double xRatio,
    required double yRatio,
    required String urgency,
  }) async {
    final incidentId = 'INC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    
    final incidentData = {
      'id': incidentId,
      'category': category,
      'description': description,
      'campusZone': campusZone,
      'roomNumber': roomNumber,
      'latitude': latitude,
      'longitude': longitude,
      'xRatio': xRatio,
      'yRatio': yRatio,
      'urgency': urgency,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
      'etaSeconds': 180,
    };

    // Broadcast alert to all connected dispatchers
    session.messages.postMessage(
      channelCampusEmergency,
      SimpleMessage('sos_beacon_triggered'),
    );

    // Schedule SLA timer (escalate after 3 mins if unassigned)
    await session.serverpod.futureCallWithDelay(
      'slaEscalationFutureCall',
      null,
      const Duration(minutes: 3),
    );

    session.log('SOS $incidentId logged for zone $campusZone', level: LogLevel.info);
    return incidentData;
  }

  // Assign patrol guard to incident
  Future<bool> assignResponder(
    Session session, {
    required String incidentId,
    required String responderId,
  }) async {
    final hasClearance = await session.isUserSignedIn;
    session.log('Assigning $responderId -> $incidentId (dispatcher auth: $hasClearance)');

    session.messages.postMessage(
      channelDispatcherAlerts,
      SimpleMessage('unit_assigned'),
    );

    return true;
  }

  // Update status (e.g. enRoute -> arrived -> resolved)
  Future<bool> updateIncidentStatus(
    Session session, {
    required String incidentId,
    required String status,
  }) async {
    session.log('Incident $incidentId -> $status');

    session.messages.postMessage(
      channelCampusEmergency,
      SimpleMessage('status_updated'),
    );

    return true;
  }

  @override
  Future<void> streamOpened(StreamingSession session) async {
    session.messages.addListener(channelCampusEmergency, (message) {
      sendStreamMessage(session, message);
    });
  }
}


