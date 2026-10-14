import 'dart:math' as math;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class TelemetryEndpoint extends Endpoint {
  static const String channelFleetTelemetry = 'telemetry:fleet';
  static const String channelProximityAlerts = 'telemetry:proximity';
  static String zoneChannel(String zone) => 'zone:${zone.toLowerCase().replaceAll(' ', '_')}';
  static String incidentChannel(String incidentId) => 'incident:$incidentId';

  // Sort available guards by distance to the incident
  Future<List<Map<String, dynamic>>> filterRespondersWithinRadius(
    Session session, {
    required double centerLatitude,
    required double centerLongitude,
    required double radiusMeters,
    required List<Map<String, dynamic>> responderPool,
  }) async {
    final filtered = <Map<String, dynamic>>[];

    for (final responder in responderPool) {
      final rLat = responder['latitude'] as double? ?? 0.0;
      final rLon = responder['longitude'] as double? ?? 0.0;
      final distance = _calculateHaversineDistance(centerLatitude, centerLongitude, rLat, rLon);

      if (distance <= radiusMeters) {
        final withDistance = Map<String, dynamic>.from(responder);
        withDistance['distanceMeters'] = distance.round();
        filtered.add(withDistance);
      }
    }

    filtered.sort((a, b) => (a['distanceMeters'] as int).compareTo(b['distanceMeters'] as int));
    return filtered;
  }

  // Update responder location and notify subscribers
  Future<Map<String, dynamic>> updateResponderGps(
    Session session, {
    required String responderId,
    required String currentZone,
    required double currentLatitude,
    required double currentLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double speedKmh,
    String? activeIncidentId,
  }) async {
    final distanceMeters = _calculateHaversineDistance(
      currentLatitude,
      currentLongitude,
      targetLatitude,
      targetLongitude,
    );

    final bearingDegrees = _calculateBearing(
      currentLatitude,
      currentLongitude,
      targetLatitude,
      targetLongitude,
    );

    final speedMps = (speedKmh > 0 ? speedKmh : 18.0) * (1000 / 3600);
    final etaSeconds = (distanceMeters / speedMps).round();
    final isProximityAlert = distanceMeters <= 50.0;

    final telemetryPayload = {
      'responderId': responderId,
      'zone': currentZone,
      'latitude': currentLatitude,
      'longitude': currentLongitude,
      'distanceMeters': distanceMeters.round(),
      'bearingDegrees': bearingDegrees.round(),
      'etaSeconds': etaSeconds,
      'isProximityAlert': isProximityAlert,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Publish to fleet channel and zone channel
    session.messages.postMessage(channelFleetTelemetry, SimpleMessage('fleet_telemetry_updated'));
    session.messages.postMessage(zoneChannel(currentZone), SimpleMessage('zone_telemetry_updated'));

    // Send direct update to victim if assigned
    if (activeIncidentId != null) {
      session.messages.postMessage(incidentChannel(activeIncidentId), SimpleMessage('incident_telemetry_updated'));
    }

    // Trigger proximity alert if guard is within 50m
    if (isProximityAlert) {
      session.messages.postMessage(channelProximityAlerts, SimpleMessage('proximity_alert'));
    }

    return telemetryPayload;
  }

  // Haversine distance in meters

  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  // Compass bearing in degrees
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    final dLonRad = _degreesToRadians(lon2 - lon1);

    final y = math.sin(dLonRad) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLonRad);

    final bearingRad = math.atan2(y, x);
    return (_radiansToDegrees(bearingRad) + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);
  double _radiansToDegrees(double radians) => radians * (180.0 / math.pi);
}
