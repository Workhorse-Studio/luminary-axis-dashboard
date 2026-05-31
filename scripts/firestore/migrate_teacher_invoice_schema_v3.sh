#!/usr/bin/env bash

set -euo pipefail

APPLY=0
PROJECT_ID="${FIRESTORE_PROJECT_ID:-luminary-axis-dashboard}"
ACCESS_TOKEN="${FIRESTORE_ACCESS_TOKEN:-}"
PAGE_SIZE=200
SCANNED=0
UPDATED=0
SKIPPED=0

# Firebase web app config for this project.
# Note: this migration script only uses PROJECT_ID directly.
# Firestore write access still requires FIRESTORE_ACCESS_TOKEN or gcloud auth.
FIREBASE_API_KEY='AIzaSyDF3h1njqzllbWvXJfaObA02-eY3BOZqeo'
FIREBASE_AUTH_DOMAIN='luminary-axis-dashboard.firebaseapp.com'
FIREBASE_PROJECT_ID='luminary-axis-dashboard'
FIREBASE_STORAGE_BUCKET='luminary-axis-dashboard.firebasestorage.app'
FIREBASE_MESSAGING_SENDER_ID='850501828016'
FIREBASE_APP_ID='1:850501828016:web:0cd8459f8db39c3614ea75'
FIREBASE_MEASUREMENT_ID='G-TLEJ3ZG9CM'

DEFAULT_AGENCY_NAME='Axis Education Centre'
DEFAULT_ADDRESS_LINE_1='9 King Albert Park #02-08'
DEFAULT_ADDRESS_LINE_2='Singapore 598332'
DEFAULT_PHONE_NUM='80626728'
DEFAULT_EMAIL='axiseducationcentre@gmail.com'

usage() {
  cat <<'EOF'
Usage:
  bash scripts/firestore/migrate_teacher_invoice_schema_v3.sh [--apply] [--project=<gcp-project-id>]

Default mode is dry-run (no writes). Add --apply to commit updates.

Auth:
  1. Set FIRESTORE_ACCESS_TOKEN directly, or
  2. Use gcloud auth application-default login / gcloud auth login and let the script call:
       gcloud auth print-access-token

Optional environment variables:
  FIRESTORE_PROJECT_ID
  FIRESTORE_ACCESS_TOKEN

This script is preconfigured for:
  projectId: luminary-axis-dashboard

Dependencies:
  curl
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

resolve_project_id() {
  if [[ -n "$PROJECT_ID" ]]; then
    return
  fi

  if command -v gcloud >/dev/null 2>&1; then
    PROJECT_ID="$(gcloud config get-value project 2>/dev/null || true)"
    if [[ "$PROJECT_ID" == "(unset)" ]]; then
      PROJECT_ID=''
    fi
  fi

  if [[ -z "$PROJECT_ID" ]]; then
    printf 'Missing Firestore project id. Pass --project=... or set FIRESTORE_PROJECT_ID.\n' >&2
    exit 1
  fi
}

resolve_access_token() {
  if [[ -n "$ACCESS_TOKEN" ]]; then
    return
  fi

  if command -v gcloud >/dev/null 2>&1; then
    ACCESS_TOKEN="$(gcloud auth print-access-token 2>/dev/null || true)"
  fi

  if [[ -z "$ACCESS_TOKEN" ]]; then
    printf 'Missing access token. Set FIRESTORE_ACCESS_TOKEN or install/authenticate gcloud.\n' >&2
    exit 1
  fi
}

auth_header() {
  printf 'Authorization: Bearer %s' "$ACCESS_TOKEN"
}

firestore_get() {
  curl --silent --show-error --fail \
    --header "$(auth_header)" \
    "$1"
}

firestore_patch() {
  curl --silent --show-error --fail \
    --request PATCH \
    --header "$(auth_header)" \
    --header 'Content-Type: application/json' \
    --data-binary @- \
    "$1"
}

urlencode() {
  local s="$1"
  local out=''
  local i c code
  for ((i = 0; i < ${#s}; i++)); do
    c="${s:i:1}"
    case "$c" in
      [a-zA-Z0-9.~_-])
        out+="$c"
        ;;
      *)
        printf -v code '%d' "'$c"
        printf -v c '%%%02X' "$code"
        out+="$c"
        ;;
    esac
  done
  printf '%s' "$out"
}

compact_json() {
  tr -d '\n\r' <<<"$1"
}

extract_first_match() {
  local compact="$1"
  local prefix="$2"
  local rest
  rest="${compact#*${prefix}}"
  if [[ "$rest" == "$compact" ]]; then
    printf ''
    return
  fi
  printf '%s' "${rest%%\"*}"
}

extract_string_field() {
  local compact field prefix
  compact="$(compact_json "$1")"
  field="$2"
  prefix="\"${field}\":{\"stringValue\":\""
  extract_first_match "$compact" "$prefix"
}

extract_name_field() {
  extract_first_match "$(compact_json "$1")" '"name":"'
}

extract_next_page_token() {
  extract_first_match "$(compact_json "$1")" '"nextPageToken":"'
}

extract_document_names() {
  local compact
  compact="$(compact_json "$1")"
  grep -o '"name":"projects/[^"]*"' <<<"$compact" | sed 's/^"name":"//; s/"$//'
}

derive_due_date() {
  local invoice_date="$1"
  if [[ -z "$invoice_date" ]]; then
    printf ''
    return
  fi

  if date -j -f '%d-%m-%Y' "$invoice_date" '+%d-%m-%Y' >/dev/null 2>&1; then
    date -j -v+14d -f '%d-%m-%Y' "$invoice_date" '+%d-%m-%Y'
    return
  fi

  local day month year
  IFS='-' read -r day month year <<<"$invoice_date"
  if [[ -z "${day:-}" || -z "${month:-}" || -z "${year:-}" ]]; then
    printf ''
    return
  fi

  if date -d "${year}-${month}-${day} +14 days" '+%d-%m-%Y' >/dev/null 2>&1; then
    date -d "${year}-${month}-${day} +14 days" '+%d-%m-%Y'
    return
  fi

  printf ''
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

build_patch_url() {
  local doc_name="$1"
  local url="https://firestore.googleapis.com/v1/${doc_name}"
  local sep='?'
  local field
  for field in \
    agencyName \
    addressLine1 \
    addressLine2 \
    phoneNum \
    email \
    dueDateFormatted \
    schemaVersion \
    migratedAt \
    adminName \
    paidDateFormatted \
    terms; do
    url+="${sep}updateMask.fieldPaths=${field}"
    sep='&'
  done
  printf '%s' "$url"
}

fetch_document() {
  local doc_name="$1"
  local mask_fields=(
    invoiceType
    invoiceDateFormatted
    dueDateFormatted
    agencyName
    addressLine1
    addressLine2
    phoneNum
    email
  )
  local url="https://firestore.googleapis.com/v1/${doc_name}"
  local sep='?'
  local field

  for field in "${mask_fields[@]}"; do
    url+="${sep}mask.fieldPaths=${field}"
    sep='&'
  done

  firestore_get "$url"
}

process_document() {
  local doc_name="$1"
  local doc_json invoice_type invoice_date due_date agency_name address_line_1
  local address_line_2 phone_num email migrated_at patch_url payload doc_id

  doc_json="$(fetch_document "$doc_name")"
  invoice_type="$(extract_string_field "$doc_json" 'invoiceType')"
  if [[ "$invoice_type" != 'teacher' ]]; then
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  invoice_date="$(extract_string_field "$doc_json" 'invoiceDateFormatted')"
  due_date="$(extract_string_field "$doc_json" 'dueDateFormatted')"
  agency_name="$(extract_string_field "$doc_json" 'agencyName')"
  address_line_1="$(extract_string_field "$doc_json" 'addressLine1')"
  address_line_2="$(extract_string_field "$doc_json" 'addressLine2')"
  phone_num="$(extract_string_field "$doc_json" 'phoneNum')"
  email="$(extract_string_field "$doc_json" 'email')"

  if [[ -z "$agency_name" ]]; then agency_name="$DEFAULT_AGENCY_NAME"; fi
  if [[ -z "$address_line_1" ]]; then address_line_1="$DEFAULT_ADDRESS_LINE_1"; fi
  if [[ -z "$address_line_2" ]]; then address_line_2="$DEFAULT_ADDRESS_LINE_2"; fi
  if [[ -z "$phone_num" ]]; then phone_num="$DEFAULT_PHONE_NUM"; fi
  if [[ -z "$email" ]]; then email="$DEFAULT_EMAIL"; fi
  if [[ -z "$due_date" ]]; then due_date="$(derive_due_date "$invoice_date")"; fi

  migrated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  patch_url="$(build_patch_url "$doc_name")"
  doc_id="${doc_name##*/}"

  payload=$(
    cat <<EOF
{"name":"$(json_escape "$doc_name")","fields":{"agencyName":{"stringValue":"$(json_escape "$agency_name")"},"addressLine1":{"stringValue":"$(json_escape "$address_line_1")"},"addressLine2":{"stringValue":"$(json_escape "$address_line_2")"},"phoneNum":{"stringValue":"$(json_escape "$phone_num")"},"email":{"stringValue":"$(json_escape "$email")"},"dueDateFormatted":{"stringValue":"$(json_escape "$due_date")"},"schemaVersion":{"integerValue":"3"},"migratedAt":{"timestampValue":"$(json_escape "$migrated_at")"}}}
EOF
  )

  if [[ "$APPLY" -eq 1 ]]; then
    firestore_patch "$patch_url" <<<"$payload" >/dev/null
    printf '[teacher-invoice-v3] patched %s\n' "$doc_id"
  else
    printf '[teacher-invoice-v3] would patch %s\n' "$doc_id"
  fi

  UPDATED=$((UPDATED + 1))
}

main() {
  local arg page_token response base_url

  for arg in "$@"; do
    case "$arg" in
      --apply)
        APPLY=1
        ;;
      --project=*)
        PROJECT_ID="${arg#*=}"
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        printf 'Unknown argument: %s\n\n' "$arg" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  require_command curl
  resolve_project_id
  resolve_access_token

  printf '[teacher-invoice-v3] project=%s apply=%s\n' "$PROJECT_ID" "$APPLY"

  base_url="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/global/archives/invoices?pageSize=${PAGE_SIZE}"
  page_token=''

  while :; do
    if [[ -n "$page_token" ]]; then
      response="$(firestore_get "${base_url}&pageToken=$(urlencode "$page_token")")"
    else
      response="$(firestore_get "$base_url")"
    fi

    while IFS= read -r doc_name; do
      [[ -n "$doc_name" ]] || continue
      SCANNED=$((SCANNED + 1))
      process_document "$doc_name"
    done < <(extract_document_names "$response" || true)

    page_token="$(extract_next_page_token "$response")"
    [[ -n "$page_token" ]] || break
  done

  printf '[teacher-invoice-v3] done. scanned=%s updated=%s skipped=%s apply=%s\n' \
    "$SCANNED" "$UPDATED" "$SKIPPED" "$APPLY"
}

main "$@"
