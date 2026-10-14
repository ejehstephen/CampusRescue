import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/incident_model.dart';

class ServerLogEntry {
  final DateTime timestamp;
  final String tag;
  final String message;
  final String channel;
  final bool isError;

  const ServerLogEntry({
    required this.timestamp,
    required this.tag,
    required this.message,
    required this.channel,
    this.isError = false,
  });
}

class GpsTelemetryPacket {
  final String responderId;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double bearingDegrees;
  final int etaSeconds;
  final double speedKmh;
  final bool isProximityAlert;
  final DateTime timestamp;

  const GpsTelemetryPacket({
    required this.responderId,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.etaSeconds,
    required this.speedKmh,
    required this.isProximityAlert,
    required this.timestamp,
  });
}

// Client wrapper around Serverpod streams and endpoints
class ServerpodService {
  static final ServerpodService _instance = ServerpodService._internal();
  factory ServerpodService() {
    _instance._ensureControllersOpen();
    return _instance;
  }
  ServerpodService._internal();

  StreamController<IncidentModel> _incidentStreamController = StreamController<IncidentModel>.broadcast();
  StreamController<List<ResponderModel>> _fleetStreamController = StreamController<List<ResponderModel>>.broadcast();
  StreamController<GpsTelemetryPacket> _telemetryStreamController = StreamController<GpsTelemetryPacket>.broadcast();
  StreamController<ServerLogEntry> _trafficLogController = StreamController<ServerLogEntry>.broadcast();
  StreamController<String> _serverNotificationController = StreamController<String>.broadcast();

  void _ensureControllersOpen() {
    if (_incidentStreamController.isClosed) {
      _incidentStreamController = StreamController<IncidentModel>.broadcast();
    }
    if (_fleetStreamController.isClosed) {
      _fleetStreamController = StreamController<List<ResponderModel>>.broadcast();
    }
    if (_telemetryStreamController.isClosed) {
      _telemetryStreamController = StreamController<GpsTelemetryPacket>.broadcast();
    }
    if (_trafficLogController.isClosed) {
      _trafficLogController = StreamController<ServerLogEntry>.broadcast();
    }
    if (_serverNotificationController.isClosed) {
      _serverNotificationController = StreamController<String>.broadcast();
    }
  }

  Stream<IncidentModel> get incidentStream {
    _ensureControllersOpen();
    return _incidentStreamController.stream;
  }
  Stream<List<ResponderModel>> get fleetStream {
    _ensureControllersOpen();
    return _fleetStreamController.stream;
  }
  Stream<GpsTelemetryPacket> get telemetryStream {
    _ensureControllersOpen();
    return _telemetryStreamController.stream;
  }
  Stream<ServerLogEntry> get trafficLogStream {
    _ensureControllersOpen();
    return _trafficLogController.stream;
  }
  Stream<String> get serverNotifications {
    _ensureControllersOpen();
    return _serverNotificationController.stream;
  }

  final List<ServerLogEntry> _logHistory = [];
  List<ServerLogEntry> get logHistory => List.unmodifiable(_logHistory);

  final String serverpodUrl = 'https://api.campusrescue.serverpod.internal:8080';
  bool isConnected = true;

  void _log(String tag, String message, {String channel = 'server:core', bool isError = false}) {
    final entry = ServerLogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      message: message,
      channel: channel,
      isError: isError,
    );
    _logHistory.insert(0, entry);
    if (_logHistory.length > 100) _logHistory.removeLast();
    if (!_trafficLogController.isClosed) {
      _trafficLogController.add(entry);
    }
  }

  // Push new SOS alert to the stream
  void broadcastNewIncident(IncidentModel incident) {
    _ensureControllersOpen();
    if (!_incidentStreamController.isClosed) {
      _incidentStreamController.add(incident);
      _log('[STREAM]', 'Broadcasting SOS ${incident.id} (${incident.category}) in ${incident.campusZone}', channel: 'campus:emergency');
      if (!_serverNotificationController.isClosed) {
        _serverNotificationController.add('[Serverpod Streaming] Broadcasted ${incident.id} to channel "campus:emergency"');
      }
    }
  }

  void broadcastFleetUpdate(List<ResponderModel> responders) {
    if (!_fleetStreamController.isClosed) {
      _fleetStreamController.add(responders);
    }
  }

  // Calculate live telemetry and broadcast packet
  void broadcastGpsTelemetry({
    required String responderId,
    required double currentLat,
    required double currentLon,
    required double targetLat,
    required double targetLon,
    required double speedKmh,
  }) {
    final distanceMeters = calculateHaversineDistance(currentLat, currentLon, targetLat, targetLon);
    final bearingDegrees = calculateBearing(currentLat, currentLon, targetLat, targetLon);
    final speedMps = (speedKmh > 0 ? speedKmh : 18.0) * (1000 / 3600);
    final etaSeconds = (distanceMeters / speedMps).round();
    final isProximityAlert = distanceMeters <= 60.0;

    final packet = GpsTelemetryPacket(
      responderId: responderId,
      latitude: currentLat,
      longitude: currentLon,
      distanceMeters: distanceMeters,
      bearingDegrees: bearingDegrees,
      etaSeconds: etaSeconds,
      speedKmh: speedKmh,
      isProximityAlert: isProximityAlert,
      timestamp: DateTime.now(),
    );

    if (!_telemetryStreamController.isClosed) {
      _telemetryStreamController.add(packet);
    }

    if (isProximityAlert) {
      _log('[GPS PROXIMITY]', 'Responder $responderId is ${distanceMeters.toStringAsFixed(1)}m from beacon! Proximity trigger sent.', channel: 'telemetry:proximity');
    }
  }

  // Haversine distance in meters
  double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  // Compass bearing in degrees (0 - 360)
  double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final lat1Rad = lat1 * (math.pi / 180.0);
    final lat2Rad = lat2 * (math.pi / 180.0);
    final dLonRad = (lon2 - lon1) * (math.pi / 180.0);

    final y = math.sin(dLonRad) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLonRad);

    final bearingRad = math.atan2(y, x);
    return ((bearingRad * 180.0 / math.pi) + 360) % 360;
  }

  final Map<String, Timer> _futureCallTimers = {};

  // Schedule SLA escalation timer
  void scheduleSlaEscalationFutureCall(String incidentId, Duration delay, VoidCallback onEscalate) {
    _ensureControllersOpen();
    _log('[FUTURECALL]', 'Registered SlaEscalationFutureCall for $incidentId in ${delay.inSeconds}s', channel: 'serverpod:future_calls');
    if (!_serverNotificationController.isClosed) {
      _serverNotificationController.add('[Serverpod FutureCall] Registered "EscalateIncidentCall" for $incidentId in ${delay.inSeconds}s');
    }
    
    _futureCallTimers[incidentId]?.cancel();
    _futureCallTimers[incidentId] = Timer(delay, () {
      _log('[FUTURECALL EXEC]', 'Executing SlaEscalationFutureCall for $incidentId. Escalating priority.', channel: 'serverpod:future_calls');
      if (!_serverNotificationController.isClosed) {
        _serverNotificationController.add('[Serverpod FutureCall] Executing "EscalateIncidentCall" for $incidentId');
      }
      _futureCallTimers.remove(incidentId);
      onEscalate();
    });
  }

  void cancelFutureCall(String incidentId) {
    _futureCallTimers[incidentId]?.cancel();
    _futureCallTimers.remove(incidentId);
    _log('[FUTURECALL CANCEL]', 'Cancelled SlaEscalationFutureCall for $incidentId (Incident resolved/assigned)', channel: 'serverpod:future_calls');
  }

  void cancelAllFutureCalls() {
    for (final timer in _futureCallTimers.values) {
      timer.cancel();
    }
    _futureCallTimers.clear();
  }

  void dispose() {
    cancelAllFutureCalls();
    _incidentStreamController.close();
    _fleetStreamController.close();
    _telemetryStreamController.close();
    _trafficLogController.close();
    _serverNotificationController.close();
  }
}
