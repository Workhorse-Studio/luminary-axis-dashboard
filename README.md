# Axis Dashboard UI

## Features

### Admins

Dashboard
- View and onboard new students by assigning a teacher
- View and add teacher-class assignments
- View, add, and modify teacher details

Billings
- View and modify student invoices
- View teacher invoices
- Mail (individually or in bulk) invoices

Term Details
- View, allocate, modify initial session counts for each student, each term
- View, add, modify terms (including names and end dates)
- Withdraw students
- Filter by student or class and allocate in bulk

Financials
- View current and historical financial data (YTD revenue, YTD payouts, YTD profits)
- View monthly breakdowns as charts

Onboarding Form
- Standalone onboarding form for students to sign up

### Teachers
Attendance
- Multi-state attendance-taking (per-day, not per-session) and historical attendance modification
- View all (for admins) or own (for teachers) term reports

## Development

```sh
flutter pub get
flutter analyze
flutter test
```

## Operations

- Firestore and Google Sheets synchronization is implemented in Firebase
  Functions v2. See [`functions/README.md`](functions/README.md) for architecture,
  deployment, destructive bootstrap, and Apps Script authorization.
- Tracked Firestore repair and schema migration utilities live in
  [`scripts/firestore`](scripts/firestore/README.md). They default to dry-run and
  should be reviewed against a current backup before using an `--apply` option.
- Function deployment configuration is tracked in
  [`functions/sync.config.yaml`](functions/sync.config.yaml); secrets remain in
  Secret Manager.
