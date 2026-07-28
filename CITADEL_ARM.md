# Citadel ARM

The Dashboard reports ARM incidents through `LAD_Server`; browser code no
longer writes `armIssues` or `armCases` directly to Firestore.

## Runtime contract

`ArmServerIntakeSink` sends `POST /api/arm/intake` with the signed-in Firebase
user's ID token. `LAD_Server` verifies that token, adds the verified identity
to server-controlled context, and writes the incident with its service account.
The browser must never send a service-account credential or an identity claim.

The default endpoint is the deployed `axis-server` Cloud Run service. Override
it only for an explicitly configured environment:

```sh
flutter build web \
  --dart-define=CITADEL_ARM_INTAKE_URL=https://axis-server.example/api/arm/intake \
  --dart-define=CITADEL_ARM_APP_VERSION=1.0.0 \
  --dart-define=CITADEL_ARM_BUILD_NUMBER=42 \
  --dart-define=CITADEL_ARM_RELEASE_CHANNEL=production
```

Release defines are optional, but when present they are attached to ARM issue
and case records for deployment correlation.

## Current limitations

The server-only intake accepts structured ARM cases, breadcrumbs, context, and
recovery snapshots. It intentionally does not accept screenshots because the
current server-side ARM SDK has no object-storage persistence path. Screenshot
capture requests are skipped; the server returns `screenshot: not_supported`.

The committed Firestore and Storage rules deny client access to ARM documents
and screenshot paths, so ARM persistence is server-only once those rules are
deployed. The remaining application data rules intentionally retain their
legacy open posture; a separate full rules migration is still required to
secure that business data.

## Verification

```sh
flutter pub get
flutter analyze
flutter test test/unit/arm_server_intake_sink_test.dart
```
