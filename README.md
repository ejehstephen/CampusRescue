# CampusRescue

A high-stress, zero-latency campus emergency dispatch, GPS responder telemetry, and student SOS beacon platform built with Flutter and Serverpod.

## Overview
CampusRescue is designed for rapid campus emergency response with a triple-persona interface:
1. **Reporter Mode (Student Mobile Terminal)**: Zero-typing 1-tap emergency presets (Severe Anaphylaxis, Active Threat, Fire Hazard, Assault), instant beacon broadcast, and live responder ETA tracking.
2. **Dispatcher Console (Tactical Command Center)**: Real-time distress queue, automated audio alarm chimes, campus zone radar map, and direct guard dispatching.
3. **Responder Patrol (Field Personnel)**: Incident triage queue, turn-by-turn simulated GPS motion telemetry, scene arrival confirmation, and one-tap incident resolution.

## Architecture & Technology Stack
- **Frontend**: Flutter Web & Mobile with state synchronization, responsive split layouts, and Web Audio siren alert synthesizers.
- **Backend / Real-Time**: Serverpod 2.x cluster with WebSocket streaming (`campus:emergency`, `dispatcher:alerts`), high-frequency GPS telemetry, and automated SLA escalation future calls.
- **Cross-Tab Synchronization**: HTML5 BroadcastChannel protocol for synchronized state across multiple browser tabs and tactical screens in real time.

## Getting Started

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)

### Running the Flutter Client
```bash
flutter pub get
flutter run -d chrome
```

### Running Serverpod Backend (Optional)
```bash
cd server
dart bin/main.dart
```

### Testing
```bash
flutter test
```
