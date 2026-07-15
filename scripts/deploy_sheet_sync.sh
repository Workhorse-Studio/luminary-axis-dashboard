#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FUNCTIONS_DIR="$DASHBOARD_DIR/functions"
CONFIG_PATH="$FUNCTIONS_DIR/sync.config.yaml"
SECRET_NAME="SHEET_SYNC_WEBHOOK_SECRET"

resolve_gcloud_python() {
  if [[ -n "${CLOUDSDK_PYTHON:-}" ]]; then
    printf '%s' "$CLOUDSDK_PYTHON"
    return
  fi
  local candidate
  for candidate in \
    /opt/homebrew/bin/python3.11 \
    /opt/homebrew/bin/python3.13 \
    /Library/Frameworks/Python.framework/Versions/3.13/bin/python3.13 \
    /opt/homebrew/bin/python3.12 \
    /Library/Frameworks/Python.framework/Versions/3.12/bin/python3.12; do
    if [[ -x "$candidate" ]]; then
      printf '%s' "$candidate"
      return
    fi
  done
}

GCLOUD_PYTHON="$(resolve_gcloud_python)"
if [[ -n "$GCLOUD_PYTHON" ]]; then
  export CLOUDSDK_PYTHON="$GCLOUD_PYTHON"
fi

read_config() {
  local key="$1"
  node - "$CONFIG_PATH" "$key" <<'NODE'
const fs = require('node:fs');
const yaml = require(process.cwd() + '/functions/node_modules/yaml');
const [configPath, key] = process.argv.slice(2);
const value = yaml.parse(fs.readFileSync(configPath, 'utf8'))[key];
if (typeof value !== 'string' || !value) process.exit(1);
process.stdout.write(value);
NODE
}

cd "$DASHBOARD_DIR"
command -v npm >/dev/null || { echo "npm is required" >&2; exit 1; }
npm --prefix "$FUNCTIONS_DIR" ci

PROJECT_ID="$(read_config projectId)"
REGION="$(read_config region)"
RUNTIME_SERVICE_ACCOUNT="$(read_config runtimeServiceAccount)"

command -v gcloud >/dev/null || { echo "gcloud is required" >&2; exit 1; }
command -v firebase >/dev/null || { echo "firebase-tools is required" >&2; exit 1; }
command -v openssl >/dev/null || { echo "openssl is required" >&2; exit 1; }

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  compute.googleapis.com \
  cloudfunctions.googleapis.com \
  eventarc.googleapis.com \
  firestore.googleapis.com \
  pubsub.googleapis.com \
  run.googleapis.com \
  secretmanager.googleapis.com \
  sheets.googleapis.com \
  storage.googleapis.com \
  --project="$PROJECT_ID"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$RUNTIME_SERVICE_ACCOUNT" \
  --role="roles/datastore.user" \
  --condition=None \
  --quiet >/dev/null

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$RUNTIME_SERVICE_ACCOUNT" \
  --role="roles/eventarc.eventReceiver" \
  --condition=None \
  --quiet >/dev/null

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$RUNTIME_SERVICE_ACCOUNT" \
  --role="roles/run.invoker" \
  --condition=None \
  --quiet >/dev/null

if ! gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  SECRET_VALUE="$(openssl rand -hex 32)"
  printf '%s' "$SECRET_VALUE" | gcloud secrets create "$SECRET_NAME" \
    --project="$PROJECT_ID" \
    --replication-policy=automatic \
    --data-file=- >/dev/null
  unset SECRET_VALUE
fi

gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
  --project="$PROJECT_ID" \
  --member="serviceAccount:$RUNTIME_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --quiet >/dev/null

npm --prefix "$FUNCTIONS_DIR" test
npm --prefix "$FUNCTIONS_DIR" run build
firebase deploy --only functions --project="$PROJECT_ID" --non-interactive --force

ENDPOINT="$(gcloud functions describe sheetEditWebhook \
  --v2 \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --format='value(serviceConfig.uri)')"
printf 'Functions deployed.\nSheet edit endpoint: %s\n' "$ENDPOINT"
printf 'Run scripts/copy_sheet_sync_secret.sh before setupSheetSync() to copy the secret.\n'
