import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/incident_model.dart';
import '../services/serverpod_service.dart';
import '../state/emergency_state.dart';
import '../theme/app_theme.dart';
import 'dispatcher_screen.dart';
import 'reporter_screen.dart';
import 'responder_screen.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  final bool isDirectRoute;

  const MainShell({
    super.key,
    this.initialIndex = 0,
    this.isDirectRoute = false,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedViewIndex;

  @override
  void initState() {
    super.initState();
    _selectedViewIndex = widget.initialIndex;
  }

  void _showBackendStatusDialog(BuildContext context, EmergencyState state) {
    showDialog(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 3,
        child: AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.infoCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  color: AppTheme.infoCyanLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serverpod Backend Bridge',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Real-Time WebSocket & GPS Telemetry Cluster',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.infoCyanLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 580,
            height: 420,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF090D16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const TabBar(
                    indicatorColor: AppTheme.infoCyan,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.stream, size: 16),
                        text: 'Live Traffic',
                      ),
                      Tab(
                        icon: Icon(Icons.gps_fixed, size: 16),
                        text: 'GPS Telemetry',
                      ),
                      Tab(
                        icon: Icon(Icons.schema_rounded, size: 16),
                        text: 'Architecture',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Live Traffic Log
                      _buildLiveTrafficTab(ServerpodService()),
                      // Tab 2: GPS Telemetry Packet Inspector
                      _buildGpsTelemetryTab(state),
                      // Tab 3: Serverpod Architecture
                      _buildArchitectureTab(state),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                state.toggleConnectionStatus();
                Navigator.pop(ctx);
              },
              child: Text(
                state.isBackendConnected ? 'Simulate Offline' : 'Set Connected',
                style: const TextStyle(
                  color: AppTheme.infoCyanLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceElevated,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTrafficTab(ServerpodService service) {
    final logs = service.logHistory;

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors, size: 36, color: AppTheme.textMuted),
            SizedBox(height: 8),
            Text(
              'Serverpod WebSocket Streams Active',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Trigger an SOS alert or assign a responder to view real-time packets.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final log = logs[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('HH:mm:ss').format(log.timestamp),
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.infoCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.tag,
                  style: const TextStyle(
                    color: AppTheme.infoCyanLight,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.message,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGpsTelemetryTab(EmergencyState state) {
    return ListView.separated(
      itemCount: state.responders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = state.responders[index];
        final lat = 6.5200 + r.currentYRatio * 0.01;
        final lon = 3.3700 + r.currentXRatio * 0.01;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    r.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (r.isAvailable
                                  ? AppTheme.statusGreen
                                  : AppTheme.warningAmber)
                              .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.isAvailable ? 'STANDBY' : 'LIVE GPS STREAMING',
                      style: TextStyle(
                        color: r.isAvailable
                            ? AppTheme.statusGreenLight
                            : AppTheme.warningAmberLight,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Coordinates: ${lat.toStringAsFixed(5)}° N, ${lon.toStringAsFixed(5)}° E  •  Zone: ${r.currentZone}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppTheme.infoCyanLight,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Route Progress: ${(r.routeProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (r.activeIncidentId != null)
                    Text(
                      'Target: ${r.activeIncidentId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.emergencyRedLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArchitectureTab(EmergencyState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.isBackendConnected
                        ? AppTheme.statusGreen
                        : AppTheme.warningAmber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.isBackendConnected
                        ? 'Serverpod 2.x Cluster: Online (Streaming Active)'
                        : 'Simulated Offline Mode',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Serverpod Endpoints & FutureCalls:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '• `IncidentEndpoint`: Real-time WebSocket streaming on `campus:emergency` & `dispatcher:alerts`.\n• `TelemetryEndpoint`: High-frequency GPS telemetry, Haversine distance, and proximity alarms.\n• `NotificationEndpoint`: Audio chime alarms and alert triage distribution.\n• `SlaEscalationFutureCall`: Serverpod cron auto-escalating unassigned emergencies in 45s.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EmergencyState>();
    final pendingCount = state.pendingIncidentsCount;
    final isAlertActive = state.activeReporterIncident != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= 960;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(74),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App Branding & Live Persona Badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF334B), Color(0xFFBE123C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.emergencyRed.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CampusRescue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'RAPID RESPONSE SYSTEM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppTheme.infoCyanLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Center View Switcher (Desktop)
                    if (isDesktop)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF090D16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSwitcherButton(
                                  index: 0,
                                  label: 'Reporter Mode',
                                  icon: Icons.sos_rounded,
                                  badge: isAlertActive ? 'LIVE' : null,
                                  badgeColor: AppTheme.warningAmber,
                                ),
                                const SizedBox(width: 6),
                                _buildSwitcherButton(
                                  index: 1,
                                  label: 'Dispatcher Console',
                                  icon: Icons.dashboard_customize_rounded,
                                  badge: pendingCount > 0
                                      ? '$pendingCount'
                                      : null,
                                  badgeColor: AppTheme.emergencyRed,
                                ),
                                const SizedBox(width: 6),
                                _buildSwitcherButton(
                                  index: 2,
                                  label: 'Responder Patrol',
                                  icon: Icons.local_police_rounded,
                                  badge: state.enRouteIncidentsCount > 0
                                      ? '${state.enRouteIncidentsCount}'
                                      : null,
                                  badgeColor: AppTheme.warningAmber,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Backend Status Indicator
                    InkWell(
                      onTap: () => _showBackendStatusDialog(context, state),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: state.isBackendConnected
                                ? AppTheme.statusGreen.withValues(alpha: 0.6)
                                : AppTheme.warningAmber.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: state.isBackendConnected
                                    ? AppTheme.statusGreen
                                    : AppTheme.warningAmber,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (state.isBackendConnected
                                                ? AppTheme.statusGreen
                                                : AppTheme.warningAmber)
                                            .withValues(alpha: 0.8),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isDesktop
                                  ? (state.isBackendConnected
                                        ? 'Backend Connected'
                                        : 'Offline Mode')
                                  : (state.isBackendConnected
                                        ? 'Connected'
                                        : 'Offline'),
                              style: TextStyle(
                                color: state.isBackendConnected
                                    ? Colors.white
                                    : AppTheme.warningAmberLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              _buildEvaluatorHeaderBanner(context, state, isDesktop),
              if (pendingCount > 0 && _selectedViewIndex != 0)
                _buildCriticalEmergencyStrobeBanner(context, state, isDesktop),
              Expanded(
                child: IndexedStack(
                  index: _selectedViewIndex,
                  children: const [
                    ReporterScreen(),
                    DispatcherScreen(),
                    ResponderScreen(),
                  ],
                ),
              ),
            ],
          ),
          // Mobile / Tablet Bottom Switcher (when not wide desktop)
          bottomNavigationBar: !isDesktop
              ? Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF111827),
                    border: Border(
                      top: BorderSide(color: AppTheme.borderLight, width: 1.5),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMobileNavTab(
                              index: 0,
                              label: 'Reporter',
                              icon: Icons.sos_rounded,
                              badge: isAlertActive ? 'LIVE' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMobileNavTab(
                              index: 1,
                              label: 'Dispatcher',
                              icon: Icons.admin_panel_settings_rounded,
                              badge: pendingCount > 0 ? '$pendingCount' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMobileNavTab(
                              index: 2,
                              label: 'Responder',
                              icon: Icons.local_police_rounded,
                              badge: state.enRouteIncidentsCount > 0
                                  ? '${state.enRouteIncidentsCount}'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEvaluatorHeaderBanner(
    BuildContext context,
    EmergencyState state,
    bool isDesktop,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppTheme.infoCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.infoCyanLight.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.layers_rounded,
                    size: 13,
                    color: AppTheme.infoCyanLight,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'MULTI-ROLE LIVE SIMULATOR (EVALUATION MODE)',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.infoCyanLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildPersonaBadge(),
            const SizedBox(width: 16),
            if (isDesktop)
              Text(
                widget.isDirectRoute
                    ? 'Dedicated Route • Active Role'
                    : 'Role-Based Access Control Simulation Active',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaBadge() {
    final (label, icon, color) = switch (_selectedViewIndex) {
      0 => (
        'Active Persona: Student Mobile Terminal',
        Icons.phone_android_rounded,
        AppTheme.warningAmber,
      ),
      1 => (
        'Active Persona: Commander A. Ibrahim (Tactical Dispatch)',
        Icons.verified_user_rounded,
        AppTheme.infoCyanLight,
      ),
      _ => (
        'Active Persona: Officer Danladi (Field Patrol RESP-01)',
        Icons.local_police_rounded,
        AppTheme.statusGreen,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherButton({
    required int index,
    required String label,
    required IconData icon,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = _selectedViewIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedViewIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.infoCyanLight : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.infoCyan.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? AppTheme.infoCyanLight
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppTheme.emergencyRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavTab({
    required int index,
    required String label,
    required IconData icon,
    String? badge,
  }) {
    final isSelected = _selectedViewIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedViewIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.infoCyanLight : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppTheme.infoCyanLight
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.emergencyRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalEmergencyStrobeBanner(BuildContext context, EmergencyState state, bool isDesktop) {
    final pendingList = state.incidents.where((i) => i.status == IncidentStatus.pending).toList();
    final latestIncident = pendingList.isNotEmpty ? pendingList.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFF991B1B), Color(0xFF450A0A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: const Border(
          bottom: BorderSide(color: AppTheme.emergencyRed, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emergencyRed.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Flashing Alarm Siren Badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SECURITY ALARM TRIGGERED',
                          style: TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${state.pendingIncidentsCount} PENDING DISTRESS BEACON(S)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (latestIncident != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${latestIncident.id} • ${latestIncident.category} at ${latestIncident.campusZone} (${latestIncident.description})',
                      style: const TextStyle(
                        color: Color(0xFFFECACA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF991B1B),
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                state.dismissPopupAlert();
                setState(() {
                  _selectedViewIndex = 1; // Direct to Dispatcher Command Center
                });
              },
              icon: const Icon(Icons.flash_on_rounded, size: 16),
              label: const Text(
                'DISPATCH NOW',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
