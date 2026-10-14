import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/incident_model.dart';
import '../state/emergency_state.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_map_view.dart';
import '../widgets/security_clearance_gate.dart';

class DispatcherScreen extends StatefulWidget {
  const DispatcherScreen({super.key});

  @override
  State<DispatcherScreen> createState() => _DispatcherScreenState();
}

class _DispatcherScreenState extends State<DispatcherScreen> {
  String _statusFilter = 'all'; // all, pending, enRoute, resolved
  String _searchQuery = '';
  String? _selectedIncidentId;
  String? _lastPoppedAlertId;



  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(time);
  }

  void _showIncomingSosPopup(IncidentModel incident, EmergencyState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.emergencyRed, width: 2.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.emergencyRed.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.emergencyRed, width: 2),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppTheme.emergencyRed, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚨 INCOMING SOS DISTRESS BEACON', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('Immediate response dispatch required', style: TextStyle(fontSize: 12, color: AppTheme.emergencyRedLight)),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            width: 480,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Incident ID: ${incident.id}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white, fontFamily: 'monospace')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.emergencyRed.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${incident.urgency.name.toUpperCase()} PRIORITY',
                        style: const TextStyle(color: AppTheme.emergencyRed, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Category: ${incident.category}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Location: ${incident.campusZone} (${incident.roomNumber ?? "General Area"})', style: const TextStyle(fontSize: 13, color: AppTheme.infoCyanLight, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Details: ${incident.description}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                state.dismissPopupAlert();
                Navigator.pop(dialogCtx);
              },
              child: const Text('Review in Feed', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningAmber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                state.dismissPopupAlert();
                Navigator.pop(dialogCtx);
                _showDispatchDialog(incident, state);
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Dispatch Nearest Guard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  void _showDispatchDialog(IncidentModel incident, EmergencyState state) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.warningAmber),
                ),
                child: const Icon(Icons.send_rounded, color: AppTheme.warningAmber, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dispatch Responder Unit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Target: ${incident.id} • ${incident.campusZone}', style: const TextStyle(fontSize: 13, color: AppTheme.infoCyanLight, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Available Response Personnel:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.responders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final responder = state.responders[index];
                      final isAssigned = incident.assignedResponderId == responder.id;

                      return InkWell(
                        onTap: () {
                          state.assignResponder(incident.id, responder.id);
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.statusGreen,
                              behavior: SnackBarBehavior.floating,
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Dispatched ${responder.name} to ${incident.campusZone}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isAssigned
                                ? AppTheme.infoCyan.withValues(alpha: 0.15)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAssigned ? AppTheme.infoCyan : AppTheme.border,
                              width: isAssigned ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: responder.isAvailable
                                    ? AppTheme.statusGreen.withValues(alpha: 0.25)
                                    : AppTheme.warningAmber.withValues(alpha: 0.25),
                                child: Icon(
                                  responder.role.contains('Security')
                                      ? Icons.shield
                                      : responder.role.contains('Medical')
                                          ? Icons.medical_services
                                          : Icons.local_police,
                                  color: responder.isAvailable ? AppTheme.statusGreenLight : AppTheme.warningAmberLight,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(responder.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
                                        const SizedBox(width: 8),
                                        if (isAssigned)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.infoCyan,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('ASSIGNED', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${responder.role} • ${responder.currentZone}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: responder.isAvailable
                                      ? AppTheme.statusGreen.withValues(alpha: 0.2)
                                      : AppTheme.warningAmber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: responder.isAvailable ? AppTheme.statusGreen : AppTheme.warningAmber,
                                  ),
                                ),
                                child: Text(
                                  responder.isAvailable ? 'AVAILABLE' : 'BUSY',
                                  style: TextStyle(
                                    color: responder.isAvailable ? AppTheme.statusGreenLight : AppTheme.warningAmberLight,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EmergencyState>();

    // 1. If unauthorized, show Security Clearance Gate
    if (!state.isDispatcherAuthenticated) {
      return SecurityClearanceGate(
        roleTitle: 'Command Center Security Gate',
        requiredScope: 'Scope.dispatcher',
        defaultPin: EmergencyState.kDispatcherPin,
        roleBadge: 'Commander',
        onAuthenticate: (pin) => state.authenticateDispatcher(pin),
      );
    }

    final popupIncident = state.popupAlertIncident;
    if (popupIncident != null && popupIncident.id != _lastPoppedAlertId) {
      _lastPoppedAlertId = popupIncident.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && state.isDispatcherAuthenticated && state.popupAlertIncident?.id == popupIncident.id) {
          _showIncomingSosPopup(popupIncident, state);
        }
      });
    }

    final incidents = state.incidents.where((i) {
      if (_statusFilter == 'pending' && i.status != IncidentStatus.pending) return false;
      if (_statusFilter == 'enRoute' && (i.status != IncidentStatus.enRoute && i.status != IncidentStatus.arrived)) return false;
      if (_statusFilter == 'resolved' && i.status != IncidentStatus.resolved) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = i.id.toLowerCase().contains(q);
        final matchCat = i.category.toLowerCase().contains(q);
        final matchZone = i.campusZone.toLowerCase().contains(q);
        final matchDesc = i.description.toLowerCase().contains(q);
        return matchId || matchCat || matchZone || matchDesc;
      }
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1080;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security Clearance Active Banner
              _buildSecurityClearanceBar(state),
              const SizedBox(height: 16),

              // Top Metrics Cards Row
              _buildMetricsRow(state, constraints.maxWidth),
              const SizedBox(height: 20),

              // Main Section: Split Layout on Desktop
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Incident Feed & Management (58%)
                    Expanded(
                      flex: 58,
                      child: _buildIncidentFeedSection(incidents, state),
                    ),
                    const SizedBox(width: 20),

                    // Right Column: Map & Fleet Status (42%)
                    Expanded(
                      flex: 42,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 420,
                            child: CampusMapView(
                              highlightedIncidentId: _selectedIncidentId,
                              onSelectIncident: (inc) {
                                setState(() {
                                  _selectedIncidentId = inc.id;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildResponderFleetCard(state),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: 360,
                      child: CampusMapView(
                        highlightedIncidentId: _selectedIncidentId,
                        onSelectIncident: (inc) {
                          setState(() {
                            _selectedIncidentId = inc.id;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildIncidentFeedSection(incidents, state),
                    const SizedBox(height: 20),
                    _buildResponderFleetCard(state),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityClearanceBar(EmergencyState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.infoCyan.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.statusGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: AppTheme.statusGreenLight, size: 16),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clearance Active: ${state.dispatcherName} (${state.dispatcherBadge})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Serverpod Scope: Scope.dispatcher • Real-time audit active',
                        style: TextStyle(fontSize: 10, color: AppTheme.infoCyanLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.emergencyRedLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: AppTheme.emergencyRed.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              state.signOutDispatcher();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF1E293B),
                  content: Text('🔒 Command Center terminal locked. Session closed.'),
                ),
              );
            },
            icon: const Icon(Icons.lock_outline_rounded, size: 14),
            label: const Text('Lock Terminal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(EmergencyState state, double width) {
    final isCompact = width < 768;

    final cards = [
      _buildMetricCard(
        title: 'Active Alerts',
        value: '${state.activeIncidentsCount}',
        icon: Icons.notifications_active_rounded,
        accentColor: AppTheme.emergencyRed,
        subtext: '${state.pendingIncidentsCount} awaiting immediate triage',
        hasPulse: state.activeIncidentsCount > 0,
      ),
      _buildMetricCard(
        title: 'Responders En Route',
        value: '${state.enRouteIncidentsCount}',
        icon: Icons.directions_run_rounded,
        accentColor: AppTheme.warningAmber,
        subtext: 'Average response ETA: 3.2 mins',
      ),
      _buildMetricCard(
        title: 'Available Units',
        value: '${state.availableRespondersCount}/${state.responders.length}',
        icon: Icons.shield_rounded,
        accentColor: AppTheme.statusGreen,
        subtext: 'Active patrols across campus',
      ),
      _buildMetricCard(
        title: 'Resolved Today',
        value: '${state.resolvedTodayCount}',
        icon: Icons.check_circle_rounded,
        accentColor: AppTheme.infoCyan,
        subtext: '100% resolution SLA',
      ),
    ];

    if (isCompact) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: cards,
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c))).toList(),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String subtext,
    bool hasPulse = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF131C2E),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              if (hasPulse) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accentColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentFeedSection(List<IncidentModel> incidents, EmergencyState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.emergencyRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emergency_share_rounded, color: AppTheme.emergencyRed, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'Incident Triage Feed',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  '${incidents.length} TOTAL',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.infoCyanLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Filter Controls
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 40,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search by ID, zone, note...',
                    prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.infoCyan),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                ),
              ),
              _buildFilterChip('All', 'all', state.incidents.length),
              _buildFilterChip('Pending', 'pending', state.pendingIncidentsCount),
              _buildFilterChip('En Route', 'enRoute', state.enRouteIncidentsCount),
              _buildFilterChip('Resolved', 'resolved', state.resolvedTodayCount),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 14),

          // Incident Cards
          if (incidents.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 44, color: AppTheme.statusGreen),
                  SizedBox(height: 10),
                  Text('All clear! No incidents matching criteria', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('New SOS triggers from students will appear instantly', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incidents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return _buildIncidentCard(incident, state);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.emergencyRed : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.emergencyRed : AppTheme.borderLight,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(IncidentModel incident, EmergencyState state) {
    final isSelected = _selectedIncidentId == incident.id;
    final responder = state.getResponderById(incident.assignedResponderId);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (incident.status) {
      case IncidentStatus.pending:
        statusColor = AppTheme.emergencyRed;
        statusLabel = 'PENDING TRIAGE';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case IncidentStatus.acknowledged:
        statusColor = AppTheme.infoCyan;
        statusLabel = 'ACKNOWLEDGED';
        statusIcon = Icons.visibility_rounded;
        break;
      case IncidentStatus.enRoute:
        statusColor = AppTheme.warningAmber;
        statusLabel = 'EN ROUTE';
        statusIcon = Icons.directions_run_rounded;
        break;
      case IncidentStatus.arrived:
        statusColor = AppTheme.warningAmber;
        statusLabel = 'ARRIVED ON SCENE';
        statusIcon = Icons.location_on_rounded;
        break;
      case IncidentStatus.resolved:
        statusColor = AppTheme.statusGreen;
        statusLabel = 'RESOLVED';
        statusIcon = Icons.check_circle_rounded;
        break;
    }

    Color urgencyColor = incident.urgency == UrgencyLevel.high
        ? AppTheme.emergencyRed
        : (incident.urgency == UrgencyLevel.medium ? AppTheme.warningAmber : AppTheme.infoCyan);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF131C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppTheme.infoCyanLight
              : (incident.status == IncidentStatus.pending ? AppTheme.emergencyRed.withValues(alpha: 0.6) : AppTheme.borderLight),
          width: isSelected || incident.status == IncidentStatus.pending ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected ? AppTheme.infoCyan : (incident.status == IncidentStatus.pending ? AppTheme.emergencyRed : Colors.black)).withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIncidentId = incident.id;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Metadata Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // ID Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Text(
                            incident.id,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: urgencyColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: urgencyColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '${incident.urgency.name.toUpperCase()} PRIORITY',
                          style: TextStyle(
                            color: urgencyColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeTime(incident.timestamp),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category & Location Section
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.infoCyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getCategoryIcon(incident.category),
                          size: 16,
                          color: AppTheme.infoCyanLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        incident.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.textMuted),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 15, color: AppTheme.warningAmber),
                      const SizedBox(width: 3),
                      Text(
                        '${incident.campusZone}${incident.roomNumber != null ? ' • ${incident.roomNumber}' : ''}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Emergency Notes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1120),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded, size: 15, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        incident.description,
                        style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              // Assigned Responder Information Card
              if (responder != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.infoCyan.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.infoCyan.withValues(alpha: 0.2),
                        child: const Icon(Icons.person, color: AppTheme.infoCyan, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assigned: ${responder.name} (${responder.role})',
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        responder.phone,
                        style: const TextStyle(fontSize: 11, color: AppTheme.statusGreenLight, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 10),

              // Action Controls
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (incident.status == IncidentStatus.pending)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        state.updateIncidentStatus(incident.id, IncidentStatus.acknowledged);
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 15),
                      label: const Text('Acknowledge Alert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),

                  if (incident.status != IncidentStatus.resolved)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showDispatchDialog(incident, state),
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: Text(
                        incident.assignedResponderId != null ? 'Reassign Unit' : 'Dispatch Guard',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),

                  if (incident.status != IncidentStatus.resolved)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        state.updateIncidentStatus(incident.id, IncidentStatus.resolved);
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                      label: const Text('Mark Resolved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),

                  if (incident.status == IncidentStatus.resolved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.statusGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.statusGreen.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.done_all_rounded, size: 14, color: AppTheme.statusGreenLight),
                          SizedBox(width: 5),
                          Text('Incident Closed & Archived', style: TextStyle(color: AppTheme.statusGreenLight, fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponderFleetCard(EmergencyState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.infoCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_moon_rounded, color: AppTheme.infoCyan, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Active Responder Fleet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  '${state.availableRespondersCount}/${state.responders.length} Ready',
                  style: const TextStyle(fontSize: 10, color: AppTheme.statusGreenLight, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.responders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = state.responders[index];
              final isMoving = r.activeIncidentId != null && r.routeProgress < 1.0;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: r.isAvailable ? AppTheme.borderLight : AppTheme.warningAmber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: r.isAvailable
                          ? AppTheme.statusGreen.withValues(alpha: 0.2)
                          : AppTheme.warningAmber.withValues(alpha: 0.2),
                      child: Icon(
                        r.role.contains('Security')
                            ? Icons.shield
                            : r.role.contains('Medical')
                                ? Icons.medical_services
                                : Icons.local_police,
                        size: 16,
                        color: r.isAvailable ? AppTheme.statusGreenLight : AppTheme.warningAmberLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                          const SizedBox(height: 1),
                          Text('${r.role} • ${r.currentZone}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: r.isAvailable ? const Color(0xFF064E3B) : const Color(0xFF78350F),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: r.isAvailable ? AppTheme.statusGreen : AppTheme.warningAmber,
                        ),
                      ),
                      child: Text(
                        r.isAvailable ? 'STANDBY' : (isMoving ? 'MOVING (${(r.routeProgress * 100).toInt()}%)' : 'ON SCENE'),
                        style: TextStyle(
                          color: r.isAvailable ? AppTheme.statusGreenLight : AppTheme.warningAmberLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
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

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('medical')) return Icons.local_hospital_rounded;
    if (category.toLowerCase().contains('security')) return Icons.security_rounded;
    if (category.toLowerCase().contains('fire')) return Icons.local_fire_department_rounded;
    return Icons.warning_amber_rounded;
  }
}
