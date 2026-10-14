# DESIGN.md - CampusRescue Design System Specification

## Brand Philosophy: Friendly, Clear, High-Precision Emergency System
CampusRescue combines the urgency and clarity of a mission-critical emergency system with a warm, friendly, modern, and accessible interface. The design eliminates chaos during high-stress situations by utilizing clean visual hierarchy, generous white space, soft elevated cards, vibrant status accents, crisp typography, and intuitive pill controls.

---

## 1. Color System & Palette

### Surface & Background Tokens
- **Background Root (`Color(0xFF0B101D)`)**: Deep slate midnight canvas. Rich, calm, and glare-reducing.
- **Card Surface (`Color(0xFF131B2E)`)**: Soft dark indigo slate for primary cards and panels.
- **Card Elevated (`Color(0xFF1E293B)`)**: Elevated modal/dialog surfaces.
- **Card Highlight (`Color(0xFF28354D)`)**: Interactive hover state and active container background.

### Border & Divider Tokens
- **Border Default (`Color(0xFF26334D)`)**: Subtle clean structure, high accessibility.
- **Border Active/Focus (`Color(0xFF38BDF8)`)**: Sky cyan highlight.

### Action & Status Tokens
- **Emergency Crimson (`Color(0xFFFF385C)`)**: Warm neon red for SOS, high-priority alerts, and urgent dispatches.
- **Safety Emerald (`Color(0xFF10B981)`)**: Soft emerald green for standby status, resolved alerts, and online indicators.
- **Warning Amber (`Color(0xFFF59E0B)`)**: Warm golden amber for pending dispatches and en-route statuses.
- **Brand Cyan / Sapphire (`Color(0xFF06B6D4)` / `Color(0xFF38BDF8)`)**: Sky cyan and sapphire blue for primary interactive buttons, badges, and active navigation tabs.
- **Soft Indigo Accent (`Color(0xFF6366F1)`)**: Friendly secondary accent for presets and helper cards.

### Text Hierarchy Tokens
- **Primary Text (`Color(0xFFF8FAFC)`)**: 100% legibility crisp off-white.
- **Secondary Text (`Color(0xFF94A3B8)`)**: Warm slate grey for metadata, subtitles, and descriptions.
- **Muted Text (`Color(0xFF64748B)`)**: Caption text, timestamps, and subtle hints.

---

## 2. Layout & Spacing Principles
- **Grid Layout**: 12-column dynamic layout for desktop viewports; single-column fluid layout for mobile.
- **Border Radii**:
  - Small elements (Badges, Buttons): `10px` / `12px`
  - Cards & Containers: `18px`
  - Modals & Floating Shells: `24px`
- **Pill Switchers**: Rounded navigation tabs (`BorderRadius.circular(14)` or fully rounded `Pill`) for quick mode switching.

---

## 3. Component Specs

### Top Navigation Bar & Brand Header
- Dual-tone gradient logo badge (`LinearGradient(colors: [Color(0xFFFF385C), Color(0xFFE11D48)])`).
- Integrated status indicator with soft glowing status dot.
- Segmented pill control switcher for **Reporter**, **Dispatcher**, and **Responder**.

### Emergency SOS Button
- Pulsing multi-ring ripple effect (`Color(0xFFFF385C)` with dual opacity rings).
- Gentle tactile touch state, rounded geometry, and zero cognitive load.

### Emergency Preset Chips
- Friendly category icons, warm background pills, clear description hints, and 1-tap dispatch capability.

### Cards & Triage Grid
- Subtle gradient subtle borders (`Border.all(color: Color(0xFF26334D), width: 1.2)`).
- Status pills with light semi-transparent backgrounds (`Color.withValues(alpha: 0.15)`).

---

## 4. Typography
- **Primary Font**: Segoe UI / System Modern Sans.
- **Monospace Font**: Monospace for Incident IDs, Coordinates, and Timestamps.
