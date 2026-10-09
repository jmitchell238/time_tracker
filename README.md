# Time Tracker

A web app for tracking hours on property work jobs and turning them into invoices. It's installable as an app on a phone or computer, and the data syncs between everyone who signs in.

Live at https://time-tracker-jm.web.app

## What it does

- Clock in and out on a job, or log hours after the fact, with breaks and adjustments
- Jobs with their own hourly rate, or a default rate from Settings
- Expenses on a job, which go on the invoice alongside the hours
- Categories for grouping jobs
- Invoices built from entries that haven't been billed yet, exported as PDF
- Insights: hours and earnings by job and by month
- Importing past entries from a CSV file (Settings)

Sign-in is email and password. Everyone who signs in shares the same jobs, entries and invoices.

## Installing

Open the live site, then:

- Android or desktop Chrome: use the install icon in the address bar, or Add to Home Screen from the menu
- iPhone or iPad (Safari): Share → Add to Home Screen

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for running it locally and tests, [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how it's built, and [docs/RELEASE.md](docs/RELEASE.md) for deploying.
