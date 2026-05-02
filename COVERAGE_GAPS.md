# Test Coverage Gaps

Files below 100% line coverage as of 2026-05-02. Each needs a bead under TEST COVERAGE epic (time_tracker-1t4).

| Coverage | Lines | File |
|----------|-------|------|
| 0.0% | 0/23 | lib/models/expense_item.dart |
| 0.0% | 0/204 | lib/screens/job_detail_screen.dart |
| 0.0% | 0/37 | lib/theme/app_theme.dart |
| 0.0% | 0/188 | lib/widgets/log_time_sheet.dart |
| 8.3% | 1/12 | lib/models/saved_client.dart |
| 63.3% | 198/313 | lib/providers/app_provider.dart |
| 65.5% | 36/55 | lib/models/invoice.dart |
| 84.1% | 122/145 | lib/services/pdf_service.dart |
| 94.4% | 68/72 | lib/widgets/clock_in_sheet.dart |
| 96.4% | 108/112 | lib/widgets/entry_edit_sheet.dart |
| 96.7% | 87/90 | lib/screens/jobs_screen.dart |
| 98.4% | 120/122 | lib/screens/settings_screen.dart |

## Epics
- FEATURES: time_tracker-znk
- TECH DEBT: time_tracker-iet
- BUGS: time_tracker-vs3
- TEST COVERAGE: time_tracker-1t4

## Dolt Server Startup
Start the dolt server with:
```bash
dolt sql-server --config /mnt/c/Users/jmitc/workspace/time_tracker/.beads/dolt/config.yaml &
sleep 4
```
Always use this exact command. Never run bare `dolt sql-server` — it will serve from the wrong directory and wipe the database.
