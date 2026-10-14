import 'package:serverpod/serverpod.dart';
import '../endpoints/incident_endpoint.dart';
import '../endpoints/notification_endpoint.dart';
import '../endpoints/telemetry_endpoint.dart';

class Endpoints extends EndpointDispatch {
  @override
  void initializeEndpoints(Server server) {
    var endpoints = <String, Endpoint>{
      'incident': IncidentEndpoint(),
      'notification': NotificationEndpoint(),
      'telemetry': TelemetryEndpoint(),
    };

    endpoints['incident']!.initialize(server, 'incident', null);
    endpoints['notification']!.initialize(server, 'notification', null);
    endpoints['telemetry']!.initialize(server, 'telemetry', null);
  }
}
