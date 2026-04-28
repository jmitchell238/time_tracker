# Time Tracker

A Flutter web/PWA app for tracking property work hours, managing jobs, and generating invoices. Built for James & Sarah Mitchell.

## Features

- **Dashboard** — weekly/monthly/yearly earnings summary and recent entries
- **Jobs** — create and manage jobs with optional per-job hourly rate overrides; archive completed jobs
- **Log Time** — quick-entry modal with job picker, date picker, start/end time or manual duration, and description
- **Entries** — view and filter time entries by day/week/month/job; delete entries
- **Invoices** — select uninvoiced entries, preview totals, add notes, and generate a numbered invoice
- **Settings** — set a default hourly rate (applied to all jobs unless overridden)

All data is stored locally in the browser via `SharedPreferences` (no server required for Phase 1).

## Tech Stack

- **Flutter** 3.x (web target, PWA-enabled)
- **Provider** for state management
- **SharedPreferences** for local persistence
- **Google Fonts** — Lora (headings) + DM Sans (body)
- **UUID** for entity IDs

## Running Locally

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) — stable channel, 3.x or later
- Chrome (recommended for web dev)

### Steps

```bash
# From the project root
flutter pub get
flutter run -d chrome
```

The app will open in Chrome with hot-reload enabled.

### Running on a specific port

```bash
flutter run -d chrome --web-port 8080
```

## Building for Web (Production)

```bash
flutter build web --release
```

The output is in `build/web/`. Deploy that folder to any static hosting service (GitHub Pages, Netlify, Firebase Hosting, etc.).

### Deploy to GitHub Pages (manual)

1. Build: `flutter build web --release --base-href "/time_tracker/"`
2. Copy `build/web/` contents to a `gh-pages` branch or `docs/` folder
3. Enable GitHub Pages in repo settings

### Deploy to Firebase Hosting (Phase 2)

See **Phase 2 — Firebase** below.

## Installing as a PWA

After deploying, open the app in Chrome on mobile or desktop:

- **Android/Chrome**: tap the "Add to Home Screen" banner or use the browser menu
- **iOS/Safari**: tap Share → "Add to Home Screen"
- **Desktop Chrome**: click the install icon in the address bar

## Project Structure

```
lib/
├── main.dart                  # App entry point, Provider setup, bottom nav shell
├── theme/
│   └── app_theme.dart         # Dark navy/amber color palette and ThemeData
├── models/
│   ├── job.dart
│   ├── time_entry.dart
│   ├── invoice.dart
│   └── app_settings.dart
├── providers/
│   └── app_provider.dart      # ChangeNotifier — all state and persistence
├── widgets/
│   ├── stat_card.dart         # Reusable stat display card
│   └── log_time_sheet.dart    # Log Time modal bottom sheet
└── screens/
    ├── dashboard_screen.dart
    ├── jobs_screen.dart
    ├── job_detail_screen.dart
    ├── entries_screen.dart
    ├── invoices_screen.dart
    └── settings_screen.dart
web/
├── index.html                 # PWA meta tags
└── manifest.json              # PWA manifest (name, theme color, icons)
```

## Phase 2 — Firebase (Future)

Phase 2 will add:

- **Firebase Auth** — Google sign-in so both James and Sarah can log in from any device
- **Firestore** — real-time cloud sync so both users share the same data
- **Firebase Hosting** — one-command deploy (`firebase deploy`)

### Setup steps (when ready)

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Authentication (Google provider) and Firestore
3. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
4. Run: `flutterfire configure` — this generates `lib/firebase_options.dart`
5. Add packages to `pubspec.yaml`:
   ```yaml
   firebase_core: ^3.x.x
   firebase_auth: ^5.x.x
   cloud_firestore: ^5.x.x
   ```
6. Replace SharedPreferences persistence in `app_provider.dart` with Firestore reads/writes

## Development Notes

- On **WSL**, Flutter for Windows lives at `C:\src\flutter`. Use `cmd.exe /c "flutter ..."` from WSL rather than the WSL Flutter binary (which may be missing its Dart SDK).
- The app ships with sample data (jobs and entries) so it looks populated on first launch. This data is written to SharedPreferences on the first load and can be edited freely.
- Invoice numbers follow the pattern `INV-001`, `INV-002`, etc., auto-incrementing based on existing invoice count.
