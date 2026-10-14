import 'package:serverpod/serverpod.dart';
import 'src/future_calls/incident_archive_future_call.dart';
import 'src/future_calls/responder_inactivity_future_call.dart';
import 'src/future_calls/sla_escalation_future_call.dart';
import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';

void run(List<String> args) async {
  // Initialize Serverpod server
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
  );

  // Register Serverpod FutureCalls (Automated SLA Escalation Cron, Heartbeat & Archival)
  pod.registerFutureCall(
    SlaEscalationFutureCall(),
    'slaEscalationFutureCall',
  );
  pod.registerFutureCall(
    ResponderInactivityFutureCall(),
    'responderInactivityFutureCall',
  );
  pod.registerFutureCall(
    IncidentArchiveFutureCall(),
    'incidentArchiveFutureCall',
  );

  // Start the server
  await pod.start();
}

