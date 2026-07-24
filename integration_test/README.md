# Invoicing browser tests

The hermetic workflow uses fake Firestore and authentication. It covers table
pagination, fuzzy search, empty results, student details, tab-scoped actions,
manual-invoice validation, dynamic rows, preview, retry, send, and discard.

```sh
flutter drive --release \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/invoicing_workflows_test.dart \
  -d chrome --driver-port=4444 --browser-dimension=1800,1000
```

The production smoke test is opt-in and must use a release build. It creates a
single `__e2e_manual_invoice_*` student, sends one real invoice email, confirms
that no invoice document is stored, and removes the student in `finally`.

```sh
flutter drive --release \
  --driver=test_driver/production_integration_test.dart \
  --target=integration_test/production_invoicing_smoke_test.dart \
  -d chrome --driver-port=4444 --browser-dimension=1800,1000 \
  --dart-define=RUN_PRODUCTION_SMOKE=true \
  --dart-define=PROD_SMOKE_RECIPIENT=...
```

`PROD_SMOKE_ADMIN_EMAIL` and `PROD_SMOKE_ADMIN_PASSWORD` may also be supplied
when the production project requires authenticated Firestore access.
