# Architecture

A Flutter app, deployed to the web on Firebase Hosting as a PWA.

## State

All app state lives in one `ChangeNotifier`, `AppProvider` (`lib/providers/app_provider.dart`). Screens read it with `context.watch<AppProvider>()` and change it with `context.read<AppProvider>()`.

## Data

Data is stored in Cloud Firestore, under `users/{workspaceId}/`. Every signed-in user shares one workspace: its id is stored in `config/workspace`, so whoever signs in reads and writes the same data. `firestore.rules` allows any signed-in user, and sign-in is limited to the accounts set up in Firebase Auth.

Earlier versions kept everything in the browser's `SharedPreferences`. On the first launch with Firestore, `AppProvider` copies that data across once and writes a `config/migrated` marker so it doesn't happen again.

## Models

In `lib/models/`:

- `Job`: a billable job, with an optional hourly rate, business and category
- `TimeEntry`: a block of work. `hours` is the duration, and `rateOverride` is optional.
- `ActiveTimer`: a running clock-in, turned into a `TimeEntry` on clock-out
- `Invoice`: a group of entry ids. Once an entry has an `invoiceId` it counts as billed.
- `ExpenseItem`, `EntryCategory`, `Business`, `AppSettings`

The rate for an entry is the first one that's set: the entry's `rateOverride`, then the job's rate, then `AppSettings.defaultRate` (`AppProvider.getEntryRate`).

## Screens

The bottom bar has Home, Jobs, Log, Invoices and More. More leads to Insights, Categories and Settings. Screens are in `lib/screens/`, and the bottom sheets for logging, clocking in and out, breaks, adjustments and expenses are in `lib/widgets/`.

## Theme

Dark only. Colors are constants on `AppColors` in `lib/theme/app_theme.dart`. Headings use Lora, and body text uses DM Sans.
