import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/incident_model.dart';
import '../state/emergency_state.dart';
import '../theme/app_theme.dart';

class CampusMapView extends StatefulWidget {
  final Function(IncidentModel)? onSelectIncident;
  final String? highlightedIncidentId;

  const CampusMapView({
    super.key,
    this.onSelectIncident,
    this.highlightedIncidentId,
  });

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  String? _selectedZone;

  final List<MapZone> _campusZones = const [
    MapZone(
      name: 'Science Block B',
      code: 'SCI-B',
      subtitle: 'Laboratories & Classrooms',
      xRatio: 0.28,
      yRatio: 0.32,
      widthRatio: 0.28,
      heightRatio: 0.24,
      color: Color(0xFF1E40AF),
      accentColor: Color(0xFF60A5FA),
      icon: Icons.science_rounded,
    ),
    MapZone(
      name: 'Hostel Quad',
      code: 'HST-Q',
      subtitle: 'Residential Halls',
      xRatio: 0.72,
      yRatio: 0.28,
      widthRatio: 0.28,
      heightRatio: 0.26,
      color: Color(0xFF4338CA),
      accentColor: Color(0xFFA5B4FC),
      icon: Icons.hotel_rounded,
    ),
    MapZone(
      name: 'Engineering Annex',
      code: 'ENG-X',
      subtitle: 'Workshops & Robotics',
      xRatio: 0.25,
      yRatio: 0.68,
      widthRatio: 0.30,
      heightRatio: 0.24,
      color: Color(0xFF0F766E),
      accentColor: Color(0xFF2DD4BF),
      icon: Icons.precision_manufacturing_rounded,
    ),
    MapZone(
      name: 'Central Library',
      code: 'LIB-C',
      subtitle: 'Study Halls & Archives',
      xRatio: 0.62,
      yRatio: 0.65,
      widthRatio: 0.24,
      heightRatio: 0.22,
      color: Color(0xFF6D28D9),
      accentColor: Color(0xFFC084FC),
      icon: Icons.local_library_rounded,
    ),
    MapZone(
      name: 'Campus Clinic',
      code: 'MED-1',
      subtitle: 'Medical Care',
      xRatio: 0.86,
      yRatio: 0.70,
      widthRatio: 0.20,
      heightRatio: 0.22,
      color: Color(0xFF047857),
      accentColor: Color(0xFF34D399),
      icon: Icons.local_hospital_rounded,
    ),
    MapZone(
      name: 'Admin Plaza',
      code: 'ADM-0',
      subtitle: 'Security HQ',
      xRatio: 0.48,
      yRatio: 0.48,
      widthRatio: 0.20,
      heightRatio: 0.20,
      color: Color(0xFF374151),
      accentColor: Color(0xFF9CA3AF),
      icon: Icons.account_balance_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EmergencyState>();
    final incidents = state.incidents;
    final responders = state.responders;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060911),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Tactical Map Canvas (Grid, Pathways & Range Rings)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TacticalBlueprintPainter(
                    radarAngle: _radarController.value * 2 * math.pi,
                  ),
                );
              },
            ),
          ),

          // Campus Buildings, Moving Markers & En Route Trajectories
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              return Stack(
                children: [
                  // Animated Dynamic Route Polyline for Dispatched Responders
                  ...responders
                      .where(
                        (r) =>
                            r.activeIncidentId != null &&
                            r.targetXRatio != null,
                      )
                      .map((r) {
                        final targetX = r.targetXRatio! * w;
                        final targetY = r.targetYRatio! * h;
                        final currentX = r.currentXRatio * w;
                        final currentY = r.currentYRatio * h;

                        return Positioned.fill(
                          child: CustomPaint(
                            painter: _RouteTrajectoryPainter(
                              start: Offset(currentX, currentY),
                              end: Offset(targetX, targetY),
                              progress: r.routeProgress,
                              color: AppTheme.warningAmber,
                            ),
                          ),
                        );
                      }),

                  // Draw Campus Buildings
                  ..._campusZones.map((zone) {
                    final isSelected = _selectedZone == zone.name;
                    final zoneIncidents = incidents
                        .where(
                          (i) =>
                              i.campusZone == zone.name &&
                              i.status != IncidentStatus.resolved,
                        )
                        .toList();
                    final hasAlert = zoneIncidents.isNotEmpty;

                    return Positioned(
                      left: zone.xRatio * w - (zone.widthRatio * w / 2),
                      top: zone.yRatio * h - (zone.heightRatio * h / 2),
                      width: zone.widthRatio * w,
                      height: zone.heightRatio * h,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedZone = _selectedZone == zone.name
                                ? null
                                : zone.name;
                          });
                          state.setUserZone(zone.name);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? zone.color.withValues(alpha: 0.75)
                                : (hasAlert
                                      ? const Color(
                                          0xFF7F1D1D,
                                        ).withValues(alpha: 0.45)
                                      : const Color(
                                          0xFF131B2E,
                                        ).withValues(alpha: 0.85)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.infoCyanLight
                                  : (hasAlert
                                        ? AppTheme.emergencyRed
                                        : zone.accentColor.withValues(
                                            alpha: 0.4,
                                          )),
                              width: isSelected || hasAlert ? 2.0 : 1.2,
                            ),
                            boxShadow: [
                              if (isSelected || hasAlert)
                                BoxShadow(
                                  color:
                                      (hasAlert
                                              ? AppTheme.emergencyRed
                                              : zone.color)
                                          .withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          zone.icon,
                                          size: 13,
                                          color: zone.accentColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            zone.code,
                                            style: TextStyle(
                                              color: zone.accentColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (hasAlert)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.emergencyRed,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                zone.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                zone.subtitle,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Active Incident Beacons
                  ...incidents
                      .where((i) => i.status != IncidentStatus.resolved)
                      .map((incident) {
                        final zone = _campusZones.firstWhere(
                          (z) => z.name == incident.campusZone,
                          orElse: () => _campusZones[0],
                        );

                        final isHighlighted =
                            widget.highlightedIncidentId == incident.id;
                        final isPending =
                            incident.status == IncidentStatus.pending;
                        final markerColor = isPending
                            ? AppTheme.emergencyRed
                            : AppTheme.warningAmber;

                        final markerX = zone.xRatio * w;
                        final markerY = zone.yRatio * h;

                        return Positioned(
                          left: markerX - 28,
                          top: markerY - 48,
                          child: GestureDetector(
                            onTap: () =>
                                widget.onSelectIncident?.call(incident),
                            child: AnimatedBuilder(
                              animation: _radarController,
                              builder: (context, child) {
                                final pulse =
                                    math.sin(
                                          _radarController.value * math.pi * 2,
                                        ) *
                                        0.12 +
                                    1.0;

                                return Transform.scale(
                                  scale: isHighlighted ? 1.15 : pulse,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: markerColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: markerColor.withValues(
                                                alpha: 0.8,
                                              ),
                                              blurRadius: 14,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getCategoryIcon(
                                                incident.category,
                                              ),
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              incident.id,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      CustomPaint(
                                        size: const Size(8, 6),
                                        painter: _TrianglePainter(
                                          color: markerColor,
                                        ),
                                      ),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: markerColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: markerColor,
                                              blurRadius: 6,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),

                  // Moving Live Responder GPS Markers
                  ...responders.map((responder) {
                    final rX = responder.currentXRatio * w;
                    final rY = responder.currentYRatio * h;
                    final isMoving =
                        responder.activeIncidentId != null &&
                        responder.routeProgress < 1.0;

                    return Positioned(
                      left: rX - 16,
                      top: rY - 16,
                      child: Tooltip(
                        message:
                            '${responder.name} (${responder.role})\nStatus: ${responder.isAvailable ? "STANDBY" : (isMoving ? "MOVING TO TARGET (${(responder.routeProgress * 100).toInt()}%)" : "ON SCENE")}',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isMoving ? 32 : 28,
                                height: isMoving ? 32 : 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: responder.isAvailable
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (responder.isAvailable
                                                  ? AppTheme.statusGreen
                                                  : AppTheme.warningAmber)
                                              .withValues(alpha: 0.8),
                                      blurRadius: isMoving ? 14 : 8,
                                      spreadRadius: isMoving ? 3 : 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  responder.role.contains('Security')
                                      ? Icons.shield
                                      : responder.role.contains('Medical')
                                      ? Icons.medical_services
                                      : Icons.local_police,
                                  size: isMoving ? 16 : 13,
                                  color: Colors.white,
                                ),
                              ),
                              if (isMoving)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.warningAmber,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'MOVING',
                                    style: TextStyle(
                                      color: AppTheme.warningAmberLight,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  // 📍 Live User / Reporter Location Marker (Pulsing Radar Wave)
                  Positioned(
                    left: state.userXRatio * w - 22,
                    top: state.userYRatio * h - 44,
                    child: AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        final pulseValue = _radarController.value;
                        final ringRadius = 14.0 + pulseValue * 18.0;
                        final ringAlpha = (1.0 - pulseValue).clamp(0.0, 0.85);
                        final hasActiveEmergency = state.activeReporterIncident != null;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tactical Pill Badge with Zone Code
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: hasActiveEmergency
                                    ? const Color(0xFF991B1B)
                                    : const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: hasActiveEmergency ? AppTheme.emergencyRedLight : Colors.white,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (hasActiveEmergency ? AppTheme.emergencyRed : const Color(0xFF0284C7))
                                        .withValues(alpha: 0.7),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasActiveEmergency ? Icons.warning_rounded : Icons.my_location_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    hasActiveEmergency ? 'YOU (SOS ACTIVE)' : 'YOU (${state.userZone})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Pulsing Concentric GPS Target
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Expanding Radar Wave Ring
                                  Container(
                                    width: ringRadius * 1.8,
                                    height: ringRadius * 1.8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: (hasActiveEmergency
                                                ? AppTheme.emergencyRed
                                                : const Color(0xFF38BDF8))
                                            .withValues(alpha: ringAlpha),
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                  // Outer Glowing Target Disc
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (hasActiveEmergency
                                              ? AppTheme.emergencyRed
                                              : const Color(0xFF0284C7))
                                          .withValues(alpha: 0.3),
                                      border: Border.all(
                                        color: hasActiveEmergency
                                            ? AppTheme.emergencyRedLight
                                            : const Color(0xFF38BDF8),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (hasActiveEmergency
                                                  ? AppTheme.emergencyRed
                                                  : const Color(0xFF38BDF8))
                                              .withValues(alpha: 0.9),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          // Top Overlay Header & Legend
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.statusGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "CAMPUS RADAR",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0369A1).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF38BDF8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_pin_circle_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'LOC: ${state.userZone.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLegendDot(const Color(0xFF38BDF8), "You (Location)"),
                      const SizedBox(width: 8),
                      _buildLegendDot(AppTheme.emergencyRed, "Alert"),
                      const SizedBox(width: 8),
                      _buildLegendDot(AppTheme.warningAmber, "Moving Unit"),
                      const SizedBox(width: 8),
                      _buildLegendDot(AppTheme.statusGreen, "Avail"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('medical')) {
      return Icons.local_hospital_rounded;
    }
    if (category.toLowerCase().contains('security')) {
      return Icons.security_rounded;
    }
    if (category.toLowerCase().contains('fire')) {
      return Icons.local_fire_department_rounded;
    }
    return Icons.warning_amber_rounded;
  }
}

class MapZone {
  final String name;
  final String code;
  final String subtitle;
  final double xRatio;
  final double yRatio;
  final double widthRatio;
  final double heightRatio;
  final Color color;
  final Color accentColor;
  final IconData icon;

  const MapZone({
    required this.name,
    required this.code,
    required this.subtitle,
    required this.xRatio,
    required this.yRatio,
    required this.widthRatio,
    required this.heightRatio,
    required this.color,
    required this.accentColor,
    required this.icon,
  });
}

class _TacticalBlueprintPainter extends CustomPainter {
  final double radarAngle;

  _TacticalBlueprintPainter({required this.radarAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Grid
    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Campus Road Network
    final roadPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.7)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final roadGlow = Paint()
      ..color = AppTheme.infoCyan.withValues(alpha: 0.1)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    // Main Avenue Road lines
    final p1 = Offset(size.width * 0.1, size.height * 0.5);
    final p2 = Offset(size.width * 0.9, size.height * 0.5);
    final p3 = Offset(size.width * 0.5, size.height * 0.1);
    final p4 = Offset(size.width * 0.5, size.height * 0.9);

    canvas.drawLine(p1, p2, roadGlow);
    canvas.drawLine(p1, p2, roadPaint);
    canvas.drawLine(p3, p4, roadGlow);
    canvas.drawLine(p3, p4, roadPaint);

    // Radar Center & Range Circles
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final ringPaint = Paint()
      ..color = AppTheme.infoCyan.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, size.shortestSide * 0.25, ringPaint);
    canvas.drawCircle(center, size.shortestSide * 0.45, ringPaint);

    // Radar Sweep Line
    final sweepPaint = Paint()
      ..color = AppTheme.infoCyan.withValues(alpha: 0.35)
      ..strokeWidth = 2.0;

    final sweepEnd = Offset(
      center.dx + math.cos(radarAngle) * (size.longestSide * 0.6),
      center.dy + math.sin(radarAngle) * (size.longestSide * 0.6),
    );
    canvas.drawLine(center, sweepEnd, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalBlueprintPainter oldDelegate) =>
      oldDelegate.radarAngle != radarAngle;
}

class _RouteTrajectoryPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;
  final Color color;

  _RouteTrajectoryPainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, glowPaint);
    canvas.drawLine(start, end, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RouteTrajectoryPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.start != start ||
      oldDelegate.end != end;
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
