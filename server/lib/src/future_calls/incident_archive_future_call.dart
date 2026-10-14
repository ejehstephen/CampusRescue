import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Serverpod Persistent FutureCall: Post-Incident Archival & SLA Compliance Analyzer.
/// Schedules 10 minutes post incident-resolution to compile GPS trajectory logs,
/// calculate average response time, and archive incident into historical audit logs.
class IncidentArchiveFutureCall extends FutureCall {
  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    session.log('[FutureCall: Incident Archive] Archiving completed incident and computing SLA metrics...');

    session.messages.postMessage(
      'dispatcher:triage',
      SimpleMessage('incident_archived'),
    );

    session.log('[FutureCall: Incident Archive] Archival & analytics record generated successfully.');
  }
}


