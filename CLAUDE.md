# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter run                        # run on connected device / emulator
flutter run -d windows             # run as Windows desktop app
flutter test                       # run all tests (must pass 100% before committing)
flutter test test/widget_test.dart # run a single test file
flutter analyze                    # lint / static analysis
flutter build apk                  # release Android build
flutter build windows              # release Windows build
```

## Release / Deploy (PWA → Firebase Hosting)

When the user says "release", "deploy", or "push to production", run these two commands in order from the project root (`/mnt/c/Users/jmitc/workspace/time_tracker`):

```bash
# Step 1 — build the web release bundle
cmd.exe /c "cd /d C:\Users\jmitc\workspace\time_tracker && flutter build web --release"

# Step 2 — deploy to Firebase Hosting (firebase is at AppData\Roaming\npm\firebase.cmd)
cmd.exe /c "cd /d C:\Users\jmitc\workspace\time_tracker && C:\Users\jmitc\AppData\Roaming\npm\firebase.cmd deploy --only hosting"
```

Both commands must run via `cmd.exe /c` from WSL because the Windows Flutter SDK is used (WSL dart-sdk is broken). Always run `flutter test` first to confirm all tests pass before deploying.

## Architecture

**State management:** single `ChangeNotifier` — `lib/providers/app_provider.dart`. Every screen reads from and writes to this one provider via `context.watch<AppProvider>()` / `context.read<AppProvider>()`. There is no other state layer.

**Persistence:** all data is stored in `SharedPreferences` as JSON strings under five keys: `jobs`, `entries`, `invoices`, `settings`, `active_timers`. `AppProvider.load()` hydrates everything on startup; `_save()` writes all five keys on every mutation.

**Models** (`lib/models/`):
- `Job` — billable job with optional per-job `rate`
- `TimeEntry` — logged work block; `hours` is the canonical duration; `rateOverride` is optional
- `Invoice` — groups `TimeEntry` IDs; once an entry has an `invoiceId` it is considered invoiced
- `AppSettings` — currently just `defaultRate`
- `ActiveTimer` — in-progress clock-in session; converted to a `TimeEntry` on clock-out

**Rate resolution order:** `TimeEntry.rateOverride` → `Job.rate` → `AppSettings.defaultRate` (see `AppProvider.getEntryRate`).

**Time entry creation paths:**
1. `LogTimeSheet` (bottom sheet) — manual entry with start/end time picker or direct hours input
2. `ClockInSheet` (bottom sheet) → `AppProvider.clockIn()` creates an `ActiveTimer` → `AppProvider.clockOut()` converts it to a `TimeEntry`
3. `JobDetailScreen` — per-job start/stop timer buttons that delegate to `startTimer` / `stopTimer` wrappers

**Navigation:** `AppShell` in `main.dart` uses `IndexedStack` + a custom bottom nav bar (5 tabs: Dashboard, Jobs, Entries, Invoices, Settings).

**Theme:** dark-only. All colors are constants on `AppColors` (`lib/theme/app_theme.dart`). Lora is used for headings/titles; DM Sans for body/labels. Never introduce a light theme or change the color palette without approval.

## Constraints

- Do not drop or alter existing time entries or jobs during any data migration.
- `AppProvider._save()` must always write all five keys together; never save a subset.
- Default data (`_defaultJobs`, `_defaultEntries`, `_defaultInvoices`) is seeded only on first launch (when the key is absent from SharedPreferences).
