# Firestore / Google Sheets Sync

This Firebase Functions v2 module keeps the managed tabs in the Axis Education
spreadsheet synchronized with Firestore. Firestore is the source of truth at
bootstrap. Runtime updates are bidirectional:

- Firestore writes invoke document-specific functions and upsert one Sheet row.
- Human Sheet edits invoke an installable Apps Script trigger, which signs and
  sends only the changed rows and fields to `sheetEditWebhook`.
- API/script writes to Sheets do not fire `onEdit`, preventing sync loops.

## Configuration

Tracked mappings and non-secret deployment values live in `sync.config.yaml`.
Secrets must not be added to this file.

Rows use these control columns:

- `docId`: stable Firestore document ID.
- `parentId`: class ID for archive subcollections.
- `_version`: Firestore update time, hidden and protected.
- `_fieldHashes`: per-field conflict baseline, hidden and protected.
- `_delete`: checkbox that deletes the Firestore document and leaves a tombstone.
- `_syncStatus`: `OK`, queued, conflict, or error state.

Each tab includes an `Active records` filter view that excludes `_delete = TRUE`.

## Verify

```sh
cd DashboardUI/functions
npm install
npm test
npm run build
```

## Deploy

Create the webhook secret once and grant the runtime service account Firestore
access. The deployment script in `../scripts/deploy_sheet_sync.sh` performs these
steps without putting the secret in source control.

## Destructive bootstrap

This removes and recreates all managed tabs from current Firestore documents:

```sh
gcloud auth application-default login \
  --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/spreadsheets
cd DashboardUI/functions
npm ci
npm run bootstrap:sheets -- --confirm-destroy-sheet-data
```

Bootstrap uses the authenticated operator's Application Default Credentials.
No service-account key should be created or downloaded. Deployed functions use
the configured runtime service account through their Cloud Run identity.

## Apps Script

After deployment:

1. Open the target spreadsheet and select **Extensions > Apps Script**.
2. Replace `Code.gs` with `apps-script/Code.gs`. The tracked `appsscript.json`
   records the scopes Apps Script will infer during authorization.
3. Run `../scripts/copy_sheet_sync_secret.sh` locally to place the secret on the
   clipboard.
4. Run `setupSheetSync()` in Apps Script. Leave the endpoint prompt blank to use
   the deployed default, paste the secret at the second prompt, and authorize the
   requested permissions as `siddharth.chitikela@gmail.com`.

The setup function replaces any prior `handleSheetEdit` trigger, so it is safe to
run again after updating the Apps Script source.

## Operations

- Treat Firestore as the source of truth when rebuilding the workbook.
- Do not rename managed tabs or control columns without updating
  `sync.config.yaml` and the sync code together.
- A human Sheet edit sets `_syncStatus` while processing. Conflicts are resolved
  per field using the stored hashes and current Firestore update time.
- Checking `_delete` deletes the Firestore document and leaves a filtered
  tombstone row for auditability.
- Apps Script authorization is the only manual deployment step. Firestore to
  Sheets works after Functions deployment; Sheets to Firestore starts after
  `setupSheetSync()` creates the installable edit trigger.
