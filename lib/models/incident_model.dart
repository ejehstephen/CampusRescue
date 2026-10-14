import 'package:flutter/foundation.dart';

// --- ENUMS ---

enum IncidentStatus { pending, acknowledged, enRoute, arrived, resolved }

enum UrgencyLevel { high, medium, low }

// --- MODELS ---

@immutable
class IncidentModel {
  final String id;
  final String category;
  final String description;
  final String campusZone;
  final String? roomNumber;
  final double latitude;
  final double longitude;
  final double xRatio; // Normalized map X coordinate (0.0 to 1.0)
  final double yRatio; // Normalized map Y coordinate (0.0 to 1.0)
  final UrgencyLevel urgency;
  final IncidentStatus status;
  final DateTime timestamp;
  final String? assignedResponderId;
  final int? etaSeconds;

  const IncidentModel({
    required this.id,
    required this.category,
    required this.description,
    required this.campusZone,
    this.roomNumber,
    required this.latitude,
    required this.longitude,
    this.xRatio = 0.28,
    this.yRatio = 0.32,
    this.urgency = UrgencyLevel.high,
    this.status = IncidentStatus.pending,
    required this.timestamp,
    this.assignedResponderId,
    this.etaSeconds,
  });

  IncidentModel copyWith({
    String? id,
    String? category,
    String? description,
    String? campusZone,
    String? roomNumber,
    double? latitude,
    double? longitude,
    double? xRatio,
    double? yRatio,
    UrgencyLevel? urgency,
    IncidentStatus? status,
    DateTime? timestamp,
    String? assignedResponderId,
    int? etaSeconds,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      campusZone: campusZone ?? this.campusZone,
      roomNumber: roomNumber ?? this.roomNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      xRatio: xRatio ?? this.xRatio,
      yRatio: yRatio ?? this.yRatio,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      assignedResponderId: assignedResponderId ?? this.assignedResponderId,
      etaSeconds: etaSeconds ?? this.etaSeconds,
    );
  }

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      campusZone: json['campusZone'] as String,
      roomNumber: json['roomNumber'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 6.5244,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 3.3792,
      xRatio: (json['xRatio'] as num?)?.toDouble() ?? 0.28,
      yRatio: (json['yRatio'] as num?)?.toDouble() ?? 0.32,
      urgency: UrgencyLevel.values.firstWhere(
        (u) => u.name == json['urgency'],
        orElse: () => UrgencyLevel.high,
      ),
      status: IncidentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => IncidentStatus.pending,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      assignedResponderId: json['assignedResponderId'] as String?,
      etaSeconds: json['etaSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'description': description,
    'campusZone': campusZone,
    'roomNumber': roomNumber,
    'latitude': latitude,
    'longitude': longitude,
    'xRatio': xRatio,
    'yRatio': yRatio,
    'urgency': urgency.name,
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
    'assignedResponderId': assignedResponderId,
    'etaSeconds': etaSeconds,
  };
}

@immutable
class ResponderModel {
  final String id;
  final String name;
  final String role; // e.g. "Security Guard", "Paramedic"
  final String phone;
  final bool isAvailable;
  final String currentZone;
  final double currentXRatio;
  final double currentYRatio;
  final double? targetXRatio;
  final double? targetYRatio;
  final double routeProgress; // 0.0 to 1.0 (moving towards incident)
  final String? activeIncidentId;

  const ResponderModel({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.isAvailable = true,
    required this.currentZone,
    this.currentXRatio = 0.5,
    this.currentYRatio = 0.5,
    this.targetXRatio,
    this.targetYRatio,
    this.routeProgress = 0.0,
    this.activeIncidentId,
  });

  ResponderModel copyWith({
    String? id,
    String? name,
    String? role,
    String? phone,
    bool? isAvailable,
    String? currentZone,
    double? currentXRatio,
    double? currentYRatio,
    double? targetXRatio,
    double? targetYRatio,
    double? routeProgress,
    String? activeIncidentId,
  }) {
    return ResponderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isAvailable: isAvailable ?? this.isAvailable,
      currentZone: currentZone ?? this.currentZone,
      currentXRatio: currentXRatio ?? this.currentXRatio,
      currentYRatio: currentYRatio ?? this.currentYRatio,
      targetXRatio: targetXRatio ?? this.targetXRatio,
      targetYRatio: targetYRatio ?? this.targetYRatio,
      routeProgress: routeProgress ?? this.routeProgress,
      activeIncidentId: activeIncidentId ?? this.activeIncidentId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'phone': phone,
    'isAvailable': isAvailable,
    'currentZone': currentZone,
    'currentXRatio': currentXRatio,
    'currentYRatio': currentYRatio,
    'routeProgress': routeProgress,
    'activeIncidentId': activeIncidentId,
  };
}

// Preset emergency for 1-tap instant action
@immutable
class EmergencyPreset {
  final String id;
  final String category;
  final String title;
  final String defaultNotes;
  final UrgencyLevel urgency;
  final String iconEmoji;

  const EmergencyPreset({
    required this.id,
    required this.category,
    required this.title,
    required this.defaultNotes,
    this.urgency = UrgencyLevel.high,
    required this.iconEmoji,
  });
}
