#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="${SCRIPT_DIR}/../functions/sync.config.yaml"
PROJECT_ID="$(sed -n 's/^projectId:[[:space:]]*//p' "${CONFIG_PATH}" | head -n 1)"
SECRET_NAME="SHEET_SYNC_WEBHOOK_SECRET"
export CLOUDSDK_PYTHON="${CLOUDSDK_PYTHON:-/opt/homebrew/bin/python3.11}"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "Unable to read projectId from ${CONFIG_PATH}." >&2
  exit 1
fi

if ! command -v pbcopy >/dev/null; then
  echo "pbcopy is required on this setup." >&2
  exit 1
fi

gcloud secrets versions access latest \
  --secret="$SECRET_NAME" \
  --project="$PROJECT_ID" | tr -d '\r\n' | pbcopy
printf 'The Apps Script webhook secret is now on the clipboard.\n'
