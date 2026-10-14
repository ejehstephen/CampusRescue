import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/incident_model.dart';
import '../state/emergency_state.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_map_view.dart';
import '../widgets/security_clearance_gate.dart';

class ResponderScreen extends StatefulWidget {
  const ResponderScreen({super.key});

  @override
  State<ResponderScreen> createState() => _ResponderScreenState();
}

class _ResponderScreenState extends State<ResponderScreen> {
  String _selectedResponderId = 'RESP-01'; // Default: Officer Danladi

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EmergencyState>();

    // 1. If unauthorized, show Patrol Terminal Security Gate
    if (!state.isResponderAuthenticated) {
      return SecurityClearanceGate(
        roleTitle: 'Responder Patrol Terminal',
        requiredScope: 'Scope.responder',
        defaultPin: EmergencyState.kResponderPin,
        roleBadge: 'Field Officer',
        onAuthenticate: (pin) => state.authenticateResponder(pin),
      );
    }

    final responder = state.getResponderById(_selectedResponderId) ?? state.responders.first;
    
    // Find incident assigned to this responder or pending incidents
    final activeAssignedIncident = state.incidents.cast<IncidentModel?>().firstWhere(
      (i) => i?.assignedResponderId == responder.id && i?.status != IncidentStatus.resolved,
      orElse: () => null,
    );

    final pendingIncidents = state.incidents.where((i) => i.status == IncidentStatus.pending).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Responder Profile Header & Selector
                  _buildResponderHeader(responder, state),
                  const SizedBox(height: 20),

                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Active Mission & Quick Actions (50%)
                        Expanded(
                          flex: 50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildActiveMissionSection(responder, activeAssignedIncident, state),
                              const SizedBox(height: 20),
                              _buildPendingAlertsSection(pendingIncidents, responder, state),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Right Column: Tactical Radar Map (50%)
                        Expanded(
                          flex: 50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 440,
                                child: CampusMapView(
                                  highlightedIncidentId: activeAssignedIncident?.id,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTelemetryCard(responder, activeAssignedIncident),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildActiveMissionSection(responder, activeAssignedIncident, state),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 340,
                          child: CampusMapView(
                            highlightedIncidentId: activeAssignedIncident?.id,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTelemetryCard(responder, activeAssignedIncident),
                        const SizedBox(height: 20),
                        _buildPendingAlertsSection(pendingIncidents, responder, state),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponderHeader(ResponderModel responder, EmergencyState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: responder.isAvailable
                      ? AppTheme.statusGreen.withValues(alpha: 0.25)
                      : AppTheme.warningAmber.withValues(alpha: 0.25),
                  child: Icon(
                    responder.role.contains('Medical')
                        ? Icons.medical_services
                        : Icons.shield,
                    color: responder.isAvailable ? AppTheme.statusGreenLight : AppTheme.warningAmberLight,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        responder.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${responder.role} • ${responder.currentZone}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.infoCyanLight, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Switch Responder Profile Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedResponderId,
                    dropdownColor: const Color(0xFF111827),
                    icon: const Icon(Icons.arrow_drop_down, color: AppTheme.infoCyanLight),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    items: state.responders.map((r) {
                      return DropdownMenuItem<String>(
                        value: r.id,
                        child: Text('${r.name} (${r.id})'),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      if (newId != null) {
                        setState(() => _selectedResponderId = newId);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Lock Patrol Terminal',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.emergencyRed.withValues(alpha: 0.15),
                  foregroundColor: AppTheme.emergencyRedLight,
                ),
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                onPressed: () {
                  state.signOutResponder();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMissionSection(ResponderModel responder, IncidentModel? incident, EmergencyState state) {
    if (incident == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderLight, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.statusGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: AppTheme.statusGreen, size: 40),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Active Emergency Dispatched',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'You are currently on standby patrol. Any new incoming distress alert assigned to you will notify immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      );
    }

    final isArrived = incident.status == IncidentStatus.arrived;
    final isEnRoute = incident.status == IncidentStatus.enRoute;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isArrived ? AppTheme.statusGreen : AppTheme.warningAmber,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isArrived ? AppTheme.statusGreen : AppTheme.warningAmber).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isArrived ? AppTheme.statusGreen : AppTheme.warningAmber).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isArrived ? Icons.location_on_rounded : Icons.directions_run_rounded,
                      size: 14,
                      color: isArrived ? AppTheme.statusGreenLight : AppTheme.warningAmberLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isArrived ? 'ON SCENE WITH VICTIM' : 'EN ROUTE TO LOCATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isArrived ? AppTheme.statusGreenLight : AppTheme.warningAmberLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Assigned at ${_formatTime(incident.timestamp)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Target Incident: ${incident.id}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppTheme.emergencyRed),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${incident.campusZone}${incident.roomNumber != null ? " • ${incident.roomNumber}" : ""}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.infoCyanLight, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reported Notes & Symptoms:',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  incident.description,
                  style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Progress Bar towards Scene
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text('GPS Navigation Route Progress', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text('${(responder.routeProgress * 100).toInt()}% Complete', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: responder.routeProgress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isArrived ? AppTheme.statusGreen : AppTheme.warningAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons: Complete Flow (Responder Accepts -> Arrives -> Marks Resolved)
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              if (isEnRoute)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    state.updateIncidentStatus(incident.id, IncidentStatus.arrived, responderId: responder.id);
                  },
                  icon: const Icon(Icons.location_on_rounded, size: 18),
                  label: const Text('Confirm Scene Arrival', style: TextStyle(fontWeight: FontWeight.w900)),
                ),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  state.updateIncidentStatus(incident.id, IncidentStatus.resolved, responderId: responder.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppTheme.statusGreen,
                      content: Text('✅ Incident successfully marked RESOLVED and closed.'),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Mark Incident Resolved', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAlertsSection(List<IncidentModel> pendingList, ResponderModel responder, EmergencyState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.radar_rounded, color: AppTheme.emergencyRed, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Campus Pending Distress Signals',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.emergencyRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${pendingList.length} PENDING',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emergencyRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (pendingList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No pending unassigned SOS distress signals.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final inc = pendingList[index];
                final isSameZone = responder.currentZone == inc.campusZone;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSameZone ? AppTheme.emergencyRed : AppTheme.emergencyRed.withValues(alpha: 0.5),
                      width: isSameZone ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      if (isSameZone)
                        BoxShadow(
                          color: AppTheme.emergencyRed.withValues(alpha: 0.25),
                          blurRadius: 12,
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emergencyRed.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    inc.id,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'monospace', color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    inc.category,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSameZone ? AppTheme.statusGreen.withValues(alpha: 0.2) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSameZone ? AppTheme.statusGreen : AppTheme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me_rounded,
                                  size: 12,
                                  color: isSameZone ? AppTheme.statusGreenLight : AppTheme.infoCyanLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSameZone ? 'NEAREST (In Your Zone!)' : 'Proximate Zone',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isSameZone ? AppTheme.statusGreenLight : AppTheme.infoCyanLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.warningAmber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${inc.campusZone} (${inc.roomNumber ?? "General Area"})',
                              style: const TextStyle(fontSize: 12, color: AppTheme.infoCyanLight, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        inc.description,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warningAmber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            state.assignResponder(inc.id, responder.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.statusGreen,
                                content: Text('⚡ Accepted SOS for ${inc.id}. Navigating to ${inc.campusZone}...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text(
                            'ACCEPT SOS & RUSH TO SCENE (PROXIMITY DISPATCH)',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(ResponderModel responder, IncidentModel? incident) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTelemetryItem('GPS Status', 'CALIBRATED', Icons.gps_fixed_rounded, AppTheme.statusGreen),
          _buildTelemetryItem('Serverpod Stream', 'CONNECTED', Icons.wifi_tethering_rounded, AppTheme.infoCyan),
          _buildTelemetryItem('SLA Target', '< 4.0 MINS', Icons.timer_rounded, AppTheme.warningAmber),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
