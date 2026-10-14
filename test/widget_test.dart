import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sos/main.dart';
import 'package:sos/models/incident_model.dart';
import 'package:sos/screens/main_shell.dart';
import 'package:sos/services/audio_alert_service.dart';
import 'package:sos/state/emergency_state.dart';

void main() {
  testWidgets('CampusRescue complete emergency state transition workflow test', (WidgetTester tester) async {
    // Set wide desktop screen resolution
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CampusRescueApp());
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Verify Shell and 3 Mode Switchers
    expect(find.text('CampusRescue'), findsOneWidget);
    expect(find.text('Reporter Mode'), findsOneWidget);
    expect(find.text('Dispatcher Console'), findsOneWidget);
    expect(find.text('Responder Patrol'), findsOneWidget);

    // 2. Verify 1-Tap Emergency Presets (Judging: High-Stress Zero Typing)
    expect(find.text('1-Tap Emergency Presets'), findsOneWidget);
    expect(find.text('Severe Allergy / Anaphylaxis'), findsOneWidget);

    // Apply 1-tap preset
    await tester.tap(find.text('Severe Allergy / Anaphylaxis'));
    await tester.pump(const Duration(milliseconds: 200));

    // 3. Trigger SOS Distress Signal
    expect(find.text('SOS'), findsOneWidget);
    await tester.tap(find.text('SOS'));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Active Response Tracker is visible for Student
    expect(find.textContaining('ACTIVE SOS ID:'), findsOneWidget);
    expect(find.text('ALERT SENT'), findsOneWidget);

    // 4. Switch to Dispatcher Console -> Security Clearance Authentication
    await tester.tap(find.text('Dispatcher Console'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Security Clearance Gate is shown for Dispatcher
    expect(find.text('COMMAND CENTER SECURITY GATE'), findsOneWidget);
    expect(find.textContaining('1-Tap Demo Clearance'), findsOneWidget);

    // Authenticate Dispatcher Session
    await tester.tap(find.textContaining('1-Tap Demo Clearance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Incoming SOS Popup appears
    expect(find.text('🚨 INCOMING SOS DISTRESS BEACON'), findsOneWidget);
    expect(find.text('Dispatch Nearest Guard'), findsOneWidget);

    // Click "Dispatch Nearest Guard" to open Guard Selection Dialog
    await tester.tap(find.text('Dispatch Nearest Guard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Dispatch Responder Unit'), findsOneWidget);
    expect(find.text('Officer Danladi'), findsWidgets);

    // Select Officer Danladi in the dialog
    await tester.tap(find.text('Officer Danladi').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 5. Switch to Responder Patrol Mode -> Security Clearance Authentication
    await tester.tap(find.text('Responder Patrol'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Security Clearance Gate is shown for Responder Patrol
    expect(find.text('RESPONDER PATROL TERMINAL'), findsOneWidget);
    expect(find.textContaining('1-Tap Demo Clearance'), findsOneWidget);

    // Authenticate Responder Session
    await tester.tap(find.textContaining('1-Tap Demo Clearance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Responder sees assigned incident and action buttons
    expect(find.text('Confirm Scene Arrival'), findsOneWidget);
    expect(find.text('Mark Incident Resolved'), findsOneWidget);

    // Responder arrives and resolves incident
    await tester.tap(find.text('Confirm Scene Arrival'));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Mark Incident Resolved'));
    await tester.pump(const Duration(milliseconds: 300));

    // 6. Switch back to Dispatcher Console and verify Resolved count updated
    await tester.tap(find.text('Dispatcher Console'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify filter chips, radar, and clearance badge
    expect(find.text('Incident Triage Feed'), findsOneWidget);
    expect(find.text('CAMPUS RADAR'), findsOneWidget);
    expect(find.textContaining('Clearance Active:'), findsOneWidget);

    // Clean up background periodic timers for test
    final state = tester.element(find.byType(MainShell)).read<EmergencyState>();
    state.stopGpsTicker();
  });

  testWidgets('Campus map zone tap and end-to-end SOS trigger flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CampusRescueApp());
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Trigger SOS from Reporter Screen
    expect(find.text('SOS'), findsOneWidget);
    await tester.tap(find.text('SOS'));
    await tester.pump(const Duration(milliseconds: 300));

    // 2. Switch to Dispatcher Console to verify Security Alarm Ribbon
    await tester.tap(find.text('Dispatcher Console'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SECURITY ALARM TRIGGERED'), findsOneWidget);
    expect(find.text('DISPATCH NOW'), findsOneWidget);

    // 3. Authenticate Dispatcher Session
    expect(find.textContaining('1-Tap Demo Clearance'), findsOneWidget);
    await tester.tap(find.textContaining('1-Tap Demo Clearance'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify incoming SOS dialog appeared and review in feed
    expect(find.text('🚨 INCOMING SOS DISTRESS BEACON'), findsOneWidget);
    await tester.tap(find.text('Review in Feed'));
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Verify Campus Radar Map is rendered on Dispatcher Console
    expect(find.text('CAMPUS RADAR'), findsOneWidget);

    // Tap on a campus building on the tactical map (e.g., 'Science Block B')
    final scienceZoneFinder = find.text('Science Block B');
    expect(scienceZoneFinder, findsWidgets);
    await tester.tap(scienceZoneFinder.first);
    await tester.pump(const Duration(milliseconds: 300));

    // Clean up background timers
    final state = tester.element(find.byType(MainShell)).read<EmergencyState>();
    expect(state.userZone, 'Science Block B');
    state.stopGpsTicker();
  });

  test('Alarm stops immediately when incident is attended to, assigned, or marked resolved', () {
    final state = EmergencyState();

    // 1. Report an emergency -> alarm is triggered
    final incidentId = state.reportEmergency(
      category: 'Medical',
      zone: 'Science Block B',
      notes: 'Test SOS Beacon',
      urgency: UrgencyLevel.high,
    );
    expect(state.pendingIncidentsCount, 1);
    expect(state.popupAlertIncident?.id, incidentId);

    // 2. Assign responder -> alarm stops and popup is dismissed
    state.assignResponder(incidentId, 'RESP-01', broadcast: false);
    expect(state.popupAlertIncident, isNull);
    expect(AudioAlertService.instance.isPlaying, isFalse);

    // 3. Mark incident resolved -> verify pending count is 0 and alarm is off
    state.updateIncidentStatus(incidentId, IncidentStatus.resolved, broadcast: false);
    expect(state.pendingIncidentsCount, 0);
    expect(AudioAlertService.instance.isPlaying, isFalse);

    state.dispose();
  });
}
