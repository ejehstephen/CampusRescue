# CampusRescue: Serverpod Architecture & Backend Core Specifications

This document specifies the pure **Serverpod 2.x** backend architecture for CampusRescue, detailing the three core technical capabilities: **Location Filtering**, **Real-Time Pub/Sub Streaming**, and **Persistent Background Timers (FutureCalls)**.

---

## 1. Location Filtering & Geofencing Engine

### A. Geodesic Proximity Math (Haversine Formula)
Serverpod computes high-accuracy ground distances between victim beacons and patrol personnel on the server side:
$$\Delta\sigma = 2 \arcsin\sqrt{\sin^2\left(\frac{\Delta\phi}{2}\right) + \cos\phi_1 \cos\phi_2 \sin^2\left(\frac{\Delta\lambda}{2}\right)}$$
$$d = R \cdot \Delta\sigma \quad (\text{where } R = 6,371,000\text{m})$$

### B. Geofenced Campus Zones
Campus incidents and responder patrols are partitioned into high-priority zones:
- `Science Block B` $(0.28, 0.32)$
- `Hostel Quad` $(0.72, 0.28)$
- `Engineering Annex` $(0.25, 0.68)$
- `Central Library` $(0.62, 0.65)$
- `Campus Clinic` $(0.86, 0.70)$
- `Admin Plaza` $(0.48, 0.48)$
- `Sports Pavilion` $(0.42, 0.85)$
- `Main Gate & Perimeter` $(0.15, 0.50)$

### C. Proximity Filtering & Nearest-Unit Auto Ranking
- `TelemetryEndpoint.filterRespondersWithinRadius()` ranks all available personnel by geodesic distance.
- Automatically flags `isProximityAlert: true` and fires emergency audio sirens when a responder comes within **$\le 50\text{m}$** of the distress location.

---

## 2. Real-Time Pub/Sub Channel Architecture

CampusRescue utilizes Serverpod's built-in WebSocket message streaming bus (`session.messages.postMessage` & `session.messages.addListener`) without any external third-party services:

| Channel Name | Scope / Audience | Frequency | Payload Description |
|---|---|---|---|
| `campus:emergency:all` | All Connected Clients | On-demand (SOS) | New distress beacons, broadcast alerts, global status |
| `zone:{campusZone}` | Officers in Zone Patrol | Real-time | Geofenced dispatch alerts targeting guards in immediate area |
| `incident:{incidentId}` | Reporter & Assigned Guard | High (200ms) | Private telemetry stream, live distance in meters, and ETA |
| `telemetry:fleet` | Dispatcher Radar Map | High (200ms) | Coordinate updates, heading bearings, and speeds |
| `telemetry:proximity` | Immediate Parties | Instant | Proximity alert ($\le 50\text{m}$) notification event |
| `dispatcher:alerts` | Authenticated Dispatchers | Real-time | Triage changes, SLA escalation warnings, unit assignments |

---

## 3. Persistent Background Timers (Serverpod FutureCalls)

Serverpod FutureCalls are durable, PostgreSQL-backed scheduled jobs that execute even across server restarts:

### A. `SlaEscalationFutureCall`
- **Trigger**: Scheduled automatically when any student triggers an SOS distress beacon (`delay: 45s`).
- **Action**: Verifies if the incident is still in `IncidentStatus.pending`. If unassigned, automatically escalates priority to **CRITICAL**, triggers audible sirens in the Dispatcher Console, and pushes urgent notifications.
- **Cancellation**: Instantly removed from the FutureCall table once a responder accepts or dispatches.

### B. `ResponderInactivityFutureCall`
- **Trigger**: Scheduled when a guard is assigned to an emergency (`delay: 60s`).
- **Action**: Checks if the responder's GPS telemetry has remained stationary or lost signal. Emits stagnation alerts and auto-reassigns to the next closest guard.

### C. `IncidentArchiveFutureCall`
- **Trigger**: Scheduled 10 minutes post incident-resolution.
- **Action**: Compiles full GPS trajectory logs, calculates total response time (Time-to-Arrive, Time-to-Resolve), and archives the incident into historical audit analytics.

---

## 4. Role-Based Scopes & Authentication

- **Public**: Reporter SOS mode (Zero login requirement for immediate safety).
- **`Scope('dispatcher')`**: Requires PIN `9944`. Grants access to triage control, manual unit override, and SLA monitoring.
- **`Scope('responder')`**: Requires PIN `1122`. Grants field officer patrol access, live navigation, and scene resolution authority.
