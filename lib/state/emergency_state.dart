import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/incident_model.dart';
import '../services/audio_alert_service.dart';
import '../services/cross_tab_sync.dart';
import '../services/serverpod_service.dart';

// Campus Zone Coordinate Lookup (normalized xRatio, yRatio)
const Map<String, List<double>> kCampusZoneCoordinates = {
  'Science Block B': [0.28, 0.32],
  'Hostel Quad': [0.72, 0.28],
  'Engineering Annex': [0.25, 0.68],
  'Central Library': [0.62, 0.65],
  'Campus Clinic': [0.86, 0.70],
  'Admin Plaza': [0.48, 0.48],
  'Sports Pavilion': [0.42, 0.85],
  'Main Gate & Perimeter': [0.15, 0.50],
};

class EmergencyState extends ChangeNotifier {
  final ServerpodService _serverpodService = ServerpodService();

  Timer? _gpsSimulationTimer;
  IncidentModel? _popupAlertIncident;

  final List<IncidentModel> _incidents = [
    IncidentModel(
      id: 'INC-8041',
      category: 'Medical',
      description: 'Severe asthma attack, student struggling to breathe.',
      campusZone: 'Science Block B',
      roomNumber: 'Room 204',
      latitude: 6.5244,
      longitude: 3.3792,
      xRatio: 0.28,
      yRatio: 0.32,
      urgency: UrgencyLevel.high,
      status: IncidentStatus.resolved,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      assignedResponderId: 'RESP-02',
    ),
    IncidentModel(
      id: 'INC-8040',
      category: 'Security',
      description: 'Physical confrontation reported near gate exit.',
      campusZone: 'Hostel Quad',
      roomNumber: 'Gate 3',
      latitude: 6.5255,
      longitude: 3.3801,
      xRatio: 0.72,
      yRatio: 0.28,
      urgency: UrgencyLevel.medium,
      status: IncidentStatus.enRoute,
      timestamp: DateTime.now().subtract(const Duration(minutes: 11)),
      assignedResponderId: 'RESP-01',
      etaSeconds: 45,
    ),
    IncidentModel(
      id: 'INC-8039',
      category: 'Fire / Hazard',
      description: 'Small chemical spill extinguished; room needs ventilation.',
      campusZone: 'Engineering Annex',
      roomNumber: 'Lab 4',
      latitude: 6.5230,
      longitude: 3.3780,
      xRatio: 0.25,
      yRatio: 0.68,
      urgency: UrgencyLevel.low,
      status: IncidentStatus.resolved,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      assignedResponderId: 'RESP-02',
    ),
  ];

  final List<ResponderModel> _responders = [
    const ResponderModel(
      id: 'RESP-01',
      name: 'Officer Danladi',
      role: 'Campus Security Patrol',
      phone: '+234 800 000 1111',
      isAvailable: false,
      currentZone: 'Hostel Quad',
      currentXRatio: 0.65,
      currentYRatio: 0.35,
      targetXRatio: 0.72,
      targetYRatio: 0.28,
      routeProgress: 0.75,
      activeIncidentId: 'INC-8040',
    ),
    const ResponderModel(
      id: 'RESP-02',
      name: 'Nurse Fatima',
      role: 'Emergency Medical Staff',
      phone: '+234 800 000 2222',
      isAvailable: true,
      currentZone: 'Campus Clinic',
      currentXRatio: 0.86,
      currentYRatio: 0.70,
    ),
    const ResponderModel(
      id: 'RESP-03',
      name: 'Patrol Team Delta',
      role: 'Rapid Security Response',
      phone: '+234 800 000 3333',
      isAvailable: true,
      currentZone: 'Central Library',
      currentXRatio: 0.62,
      currentYRatio: 0.65,
    ),
    const ResponderModel(
      id: 'RESP-04',
      name: 'Capt. Ibrahim',
      role: 'Fire Safety Marshal',
      phone: '+234 800 000 4444',
      isAvailable: true,
      currentZone: 'Engineering Annex',
      currentXRatio: 0.25,
      currentYRatio: 0.68,
    ),
  ];

  // 1-Tap Preset Emergency Actions
  final List<EmergencyPreset> _presets = const [
    EmergencyPreset(
      id: 'PRESET-MED-1',
      category: 'Medical',
      title: 'Severe Allergy / Anaphylaxis',
      defaultNotes: 'Severe allergic reaction, breathing difficulty, urgent epinephrine needed.',
      urgency: UrgencyLevel.high,
      iconEmoji: '🩺',
    ),
    EmergencyPreset(
      id: 'PRESET-MED-2',
      category: 'Medical',
      title: 'Asthma / Inhaler Needed',
      defaultNotes: 'Acute asthma attack, inhaler depleted, person collapsed.',
      urgency: UrgencyLevel.high,
      iconEmoji: '🫁',
    ),
    EmergencyPreset(
      id: 'PRESET-SEC-1',
      category: 'Security',
      title: 'Physical Threat / Assault',
      defaultNotes: 'Immediate physical violence / fight in progress. Emergency security required.',
      urgency: UrgencyLevel.high,
      iconEmoji: '🛡️',
    ),
    EmergencyPreset(
      id: 'PRESET-SEC-2',
      category: 'Security',
      title: 'Stalking / Harassment',
      defaultNotes: 'Suspicious individual tailing student, request escort immediately.',
      urgency: UrgencyLevel.medium,
      iconEmoji: '⚠️',
    ),
    EmergencyPreset(
      id: 'PRESET-FIRE-1',
      category: 'Fire / Hazard',
      title: 'Active Smoke / Fire Alarm',
      defaultNotes: 'Thick smoke and visible flame detected. Evacuation in progress.',
      urgency: UrgencyLevel.high,
      iconEmoji: '🧯',
    ),
    EmergencyPreset(
      id: 'PRESET-HAZ-1',
      category: 'Suspicious Activity',
      title: 'Unattended Bag / Prowling',
      defaultNotes: 'Suspicious backpack left unattended in corridor for over 45 minutes.',
      urgency: UrgencyLevel.low,
      iconEmoji: '🎒',
    ),
  ];

  // Active student device tracking & user location
  String? _currentActiveReporterIncidentId;
  bool _isBackendConnected = true;
  String _userZone = 'Hostel Quad';
  double _userXRatio = 0.72;
  double _userYRatio = 0.28;

  // Authentication & Security Clearance (Serverpod Role-Based Auth Simulation)
  bool _isDispatcherAuthenticated = false;
  bool _isResponderAuthenticated = false;
  final String _dispatcherName = 'Commander A. Ibrahim';
  final String _dispatcherBadge = 'DSP-772';
  static const String kDispatcherPin = '9944';
  static const String kResponderPin = '1122';

  EmergencyState() {
    _startGpsMotionTicker();
    CrossTabSync.instance.init(_onCrossTabMessage);
  }

  List<IncidentModel> get incidents => List.unmodifiable(_incidents);
  List<ResponderModel> get responders => List.unmodifiable(_responders);
  List<EmergencyPreset> get presets => _presets;
  bool get isBackendConnected => _isBackendConnected;
  String? get currentActiveReporterIncidentId => _currentActiveReporterIncidentId;
  IncidentModel? get popupAlertIncident => _popupAlertIncident;
  
  String get userZone => activeReporterIncident?.campusZone ?? _userZone;
  double get userXRatio => activeReporterIncident != null ? activeReporterIncident!.xRatio : _userXRatio;
  double get userYRatio => activeReporterIncident != null ? activeReporterIncident!.yRatio : _userYRatio;

  void setUserZone(String zone, {bool broadcast = true}) {
    final coords = kCampusZoneCoordinates[zone] ?? [0.5, 0.5];
    _userZone = zone;
    _userXRatio = coords[0];
    _userYRatio = coords[1];
    if (broadcast) {
      CrossTabSync.instance.broadcast({
        'type': 'USER_ZONE',
        'zone': zone,
      });
    }
    notifyListeners();
  }

  bool get isDispatcherAuthenticated => _isDispatcherAuthenticated;
  bool get isResponderAuthenticated => _isResponderAuthenticated;
  String get dispatcherName => _dispatcherName;
  String get dispatcherBadge => _dispatcherBadge;

  bool authenticateDispatcher(String pin) {
    if (pin.trim() == kDispatcherPin || pin.trim() == 'admin') {
      _isDispatcherAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool authenticateResponder(String pin) {
    if (pin.trim() == kResponderPin || pin.trim() == 'guard') {
      _isResponderAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void signOutDispatcher() {
    _isDispatcherAuthenticated = false;
    notifyListeners();
  }

  void signOutResponder() {
    _isResponderAuthenticated = false;
    notifyListeners();
  }

  IncidentModel? get activeReporterIncident {
    if (_currentActiveReporterIncidentId == null) return null;
    try {
      return _incidents.firstWhere((i) => i.id == _currentActiveReporterIncidentId);
    } catch (_) {
      return null;
    }
  }

  // Metrics
  int get activeIncidentsCount =>
      _incidents.where((i) => i.status != IncidentStatus.resolved).length;
  int get pendingIncidentsCount =>
      _incidents.where((i) => i.status == IncidentStatus.pending).length;
  int get enRouteIncidentsCount =>
      _incidents.where((i) => i.status == IncidentStatus.enRoute || i.status == IncidentStatus.arrived).length;
  int get resolvedTodayCount =>
      _incidents.where((i) => i.status == IncidentStatus.resolved).length;
  int get availableRespondersCount =>
      _responders.where((r) => r.isAvailable).length;

  void dismissPopupAlert() {
    _popupAlertIncident = null;
    AudioAlertService.instance.stopAlarm();
    CrossTabSync.instance.broadcast({'type': 'STOP_ALARM'});
    notifyListeners();
  }

  // Live GPS Motion Ticker for moving markers
  void _startGpsMotionTicker() {
    _gpsSimulationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      bool updated = false;

      for (int i = 0; i < _responders.length; i++) {
        final r = _responders[i];
        if (r.targetXRatio != null && r.targetYRatio != null && r.routeProgress < 1.0) {
          final newProgress = (r.routeProgress + 0.015).clamp(0.0, 1.0);
          
          // Interpolate GPS Position
          final coords = kCampusZoneCoordinates[r.currentZone] ?? [0.5, 0.5];
          final startX = coords[0];
          final startY = coords[1];
          final targetX = r.targetXRatio!;
          final targetY = r.targetYRatio!;

          final currentX = startX + (targetX - startX) * newProgress;
          final currentY = startY + (targetY - startY) * newProgress;

          // Compute simulated real-world coordinates from normalized ratio
          final currentLat = 6.5200 + currentY * 0.01;
          final currentLon = 3.3700 + currentX * 0.01;
          final targetLat = 6.5200 + targetY * 0.01;
          final targetLon = 3.3700 + targetX * 0.01;

          // Broadcast high-frequency telemetry packet to Serverpod WebSocket channel
          _serverpodService.broadcastGpsTelemetry(
            responderId: r.id,
            currentLat: currentLat,
            currentLon: currentLon,
            targetLat: targetLat,
            targetLon: targetLon,
            speedKmh: 24.0,
          );

          _responders[i] = r.copyWith(
            routeProgress: newProgress,
            currentXRatio: currentX,
            currentYRatio: currentY,
          );
          updated = true;

          // Check if responder reached the target scene
          if (newProgress >= 1.0 && r.activeIncidentId != null) {
            final incIndex = _incidents.indexWhere((inc) => inc.id == r.activeIncidentId);
            if (incIndex != -1 && _incidents[incIndex].status == IncidentStatus.enRoute) {
              _incidents[incIndex] = _incidents[incIndex].copyWith(
                status: IncidentStatus.arrived,
                etaSeconds: 0,
              );
            }
          }
        }
      }

      if (updated) {
        notifyListeners();
      }
    });
  }

  // Student Triggers SOS / Preset
  String reportEmergency({
    required String category,
    required String zone,
    String? roomNumber,
    String notes = '',
    UrgencyLevel urgency = UrgencyLevel.high,
  }) {
    final coords = kCampusZoneCoordinates[zone] ?? [0.28, 0.32];
    final incidentId = 'INC-${(DateTime.now().millisecondsSinceEpoch % 9000) + 1000}';

    final newIncident = IncidentModel(
      id: incidentId,
      category: category,
      description: notes.trim().isEmpty ? 'Distress SOS beacon raised by student.' : notes.trim(),
      campusZone: zone,
      roomNumber: roomNumber,
      latitude: 6.5244,
      longitude: 3.3792,
      xRatio: coords[0],
      yRatio: coords[1],
      urgency: urgency,
      status: IncidentStatus.pending,
      timestamp: DateTime.now(),
      etaSeconds: 180,
    );

    _userZone = zone;
    _userXRatio = coords[0];
    _userYRatio = coords[1];

    _incidents.insert(0, newIncident);
    _currentActiveReporterIncidentId = incidentId;
    _popupAlertIncident = newIncident; // Triggers instant dispatcher alert popup
    AudioAlertService.instance.startRepeatingAlarm();

    // Broadcast over Serverpod Streaming channel
    _serverpodService.broadcastNewIncident(newIncident);

    // Broadcast across multiple browser tabs / windows in real time
    CrossTabSync.instance.broadcast({
      'type': 'REPORT_EMERGENCY',
      'incident': newIncident.toJson(),
    });

    // Schedule automatic SLA future call
    _serverpodService.scheduleSlaEscalationFutureCall(incidentId, const Duration(seconds: 45), () {
      final idx = _incidents.indexWhere((i) => i.id == incidentId);
      if (idx != -1 && _incidents[idx].status == IncidentStatus.pending) {
        _incidents[idx] = _incidents[idx].copyWith(urgency: UrgencyLevel.high);
        notifyListeners();
      }
    });

    notifyListeners();
    return incidentId;
  }

  void cancelActiveReporterEmergency() {
    if (_currentActiveReporterIncidentId != null) {
      final incidentIdToCancel = _currentActiveReporterIncidentId!;
      CrossTabSync.instance.broadcast({
        'type': 'CANCEL_EMERGENCY',
        'incidentId': incidentIdToCancel,
      });

      final index = _incidents.indexWhere((i) => i.id == incidentIdToCancel);
      if (index != -1) {
        _incidents[index] = _incidents[index].copyWith(
          status: IncidentStatus.resolved,
          description: '${_incidents[index].description} [Canceled by Reporter]',
        );
        _serverpodService.cancelFutureCall(incidentIdToCancel);
      }
      if (_popupAlertIncident?.id == incidentIdToCancel) {
        _popupAlertIncident = null;
      }
      _currentActiveReporterIncidentId = null;
      AudioAlertService.instance.stopAlarm();
      CrossTabSync.instance.broadcast({'type': 'STOP_ALARM'});
      notifyListeners();
    }
  }

  void updateIncidentStatus(
    String incidentId,
    IncidentStatus newStatus, {
    String? responderId,
    bool broadcast = true,
  }) {
    final index = _incidents.indexWhere((i) => i.id == incidentId);
    if (index != -1) {
      if (newStatus == IncidentStatus.resolved) {
        _serverpodService.cancelFutureCall(incidentId);
      }

      final oldResponderId = _incidents[index].assignedResponderId;
      final assignedId = responderId ?? oldResponderId;

      _incidents[index] = _incidents[index].copyWith(
        status: newStatus,
        assignedResponderId: assignedId,
      );

      // Handle responder moving motion
      if (assignedId != null) {
        final rIndex = _responders.indexWhere((r) => r.id == assignedId);
        if (rIndex != -1) {
          final targetCoords = kCampusZoneCoordinates[_incidents[index].campusZone] ?? [0.5, 0.5];
          final shouldBeAvailable = newStatus == IncidentStatus.resolved;

          _responders[rIndex] = _responders[rIndex].copyWith(
            isAvailable: shouldBeAvailable,
            activeIncidentId: shouldBeAvailable ? null : incidentId,
            targetXRatio: shouldBeAvailable ? null : targetCoords[0],
            targetYRatio: shouldBeAvailable ? null : targetCoords[1],
            routeProgress: shouldBeAvailable ? 0.0 : 0.05,
          );
        }
      }

      // If the incident currently shown in popup was attended to or resolved, clear it
      if (_popupAlertIncident?.id == incidentId) {
        _popupAlertIncident = null;
      }

      // When an incident is attended to (enRoute, arrived, acknowledged, resolved)
      // or if no pending incidents remain, stop the siren immediately!
      if (pendingIncidentsCount == 0 ||
          newStatus == IncidentStatus.resolved ||
          newStatus == IncidentStatus.enRoute ||
          newStatus == IncidentStatus.arrived ||
          newStatus == IncidentStatus.acknowledged) {
        AudioAlertService.instance.stopAlarm();
        if (broadcast) {
          CrossTabSync.instance.broadcast({'type': 'STOP_ALARM'});
        }
      }

      if (broadcast) {
        CrossTabSync.instance.broadcast({
          'type': 'UPDATE_STATUS',
          'incidentId': incidentId,
          'status': newStatus.name,
          'responderId': assignedId,
        });
      }

      notifyListeners();
    }
  }

  void assignResponder(String incidentId, String responderId, {bool broadcast = true}) {
    if (_popupAlertIncident?.id == incidentId) {
      _popupAlertIncident = null;
    }
    updateIncidentStatus(
      incidentId,
      IncidentStatus.enRoute,
      responderId: responderId,
      broadcast: broadcast,
    );
    AudioAlertService.instance.stopAlarm();
    if (broadcast) {
      CrossTabSync.instance.broadcast({'type': 'STOP_ALARM'});
    }
    notifyListeners();
  }

  void _onCrossTabMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == 'REPORT_EMERGENCY') {
      try {
        final incMap = data['incident'] as Map<String, dynamic>;
        final inc = IncidentModel.fromJson(incMap);
        if (!_incidents.any((i) => i.id == inc.id)) {
          _incidents.insert(0, inc);
          _popupAlertIncident = inc;
          AudioAlertService.instance.startRepeatingAlarm();
          notifyListeners();
        }
      } catch (_) {}
    } else if (type == 'STOP_ALARM') {
      _popupAlertIncident = null;
      AudioAlertService.instance.stopAlarm();
      notifyListeners();
    } else if (type == 'ASSIGN_RESPONDER') {
      final incidentId = data['incidentId'] as String?;
      final responderId = data['responderId'] as String?;
      if (incidentId != null && responderId != null) {
        assignResponder(incidentId, responderId, broadcast: false);
      }
    } else if (type == 'UPDATE_STATUS') {
      final incidentId = data['incidentId'] as String?;
      final statusStr = data['status'] as String?;
      final responderId = data['responderId'] as String?;
      if (incidentId != null && statusStr != null) {
        final status = IncidentStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => IncidentStatus.pending,
        );
        updateIncidentStatus(incidentId, status, responderId: responderId, broadcast: false);
      }
    } else if (type == 'CANCEL_EMERGENCY') {
      final incidentId = data['incidentId'] as String?;
      if (incidentId != null) {
        final idx = _incidents.indexWhere((i) => i.id == incidentId);
        if (idx != -1) {
          _incidents[idx] = _incidents[idx].copyWith(status: IncidentStatus.resolved);
        }
        if (_popupAlertIncident?.id == incidentId) {
          _popupAlertIncident = null;
        }
        AudioAlertService.instance.stopAlarm();
        notifyListeners();
      }
    } else if (type == 'USER_ZONE') {
      final zone = data['zone'] as String?;
      if (zone != null) {
        setUserZone(zone, broadcast: false);
      }
    }
  }

  ResponderModel? getResponderById(String? id) {
    if (id == null) return null;
    try {
      return _responders.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void toggleConnectionStatus() {
    _isBackendConnected = !_isBackendConnected;
    _serverpodService.isConnected = _isBackendConnected;
    notifyListeners();
  }

  /// Helper to stop background periodic ticker in widget tests
  void stopGpsTicker() {
    _gpsSimulationTimer?.cancel();
    _gpsSimulationTimer = null;
  }

  @override
  void dispose() {
    stopGpsTicker();
    _serverpodService.dispose();
    super.dispose();
  }
}
