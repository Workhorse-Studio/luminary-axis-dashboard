#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"

ENV_FILE=".env"
DART_FILE=""

while (($# > 0)); do
  case "$1" in
    --env-file)
      ENV_FILE="${2:-}"
      shift 2
      ;;
    --dart-file)
      DART_FILE="${2:-}"
      shift 2
      ;;
    --help|-h)
      cat <<'EOF'
Usage: bash tool/check_arm_firebase_config.sh [--env-file PATH] [--dart-file PATH]

Checks whether the current project's Firebase config is compatible with the
ARM requirements.

Required values:
  - FB_API_KEY
  - FB_APP_ID
  - FB_MESSAGING_SENDER_ID
  - FB_PROJECT_ID

Recommended values:
  - FB_AUTH_DOMAIN
  - FB_STORAGE_BUCKET

Additional checks:
  - Firestore rules are present and not obviously public
  - Storage rules are present and not obviously public when Storage is configured

Source order:
  - a Dart options file if present (`options.dart`, `firebase_options.dart`, or `lib/firebase_options.dart`)
  - the env file passed with `--env-file` or `.env` in the current directory
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${DART_FILE}" ]]; then
  for candidate in \
    "options.dart" \
    "firebase_options.dart" \
    "lib/firebase_options.dart" \
    "lib/options.dart"; do
    if [[ -f "${candidate}" ]]; then
      DART_FILE="${candidate}"
      break
    fi
  done
fi

if [[ -n "${ENV_FILE}" && -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

get_value() {
  local key="$1"
  local value=""

  if [[ -n "${DART_FILE}" && -f "${DART_FILE}" ]]; then
    value="$(get_dart_value "${DART_FILE}" "${key}")"
  fi

  if [[ -z "${value}" ]]; then
    value="${!key:-}"
  fi

  printf '%s' "${value}"
}

get_dart_value() {
  local file="$1"
  local key="$2"
  local candidate
  local value

  for candidate in $(dart_keys_for "${key}"); do
    value="$(extract_dart_value "${file}" "${candidate}")"
    if [[ -n "${value}" ]]; then
      printf '%s' "${value}"
      return 0
    fi
  done

  printf '%s' ''
}

dart_keys_for() {
  case "$1" in
    FB_API_KEY) printf '%s\n' "FB_API_KEY" "apiKey" ;;
    FB_APP_ID) printf '%s\n' "FB_APP_ID" "appId" ;;
    FB_MESSAGING_SENDER_ID) printf '%s\n' "FB_MESSAGING_SENDER_ID" "messagingSenderId" ;;
    FB_PROJECT_ID) printf '%s\n' "FB_PROJECT_ID" "projectId" ;;
    FB_AUTH_DOMAIN) printf '%s\n' "FB_AUTH_DOMAIN" "authDomain" ;;
    FB_STORAGE_BUCKET) printf '%s\n' "FB_STORAGE_BUCKET" "storageBucket" ;;
    FB_MEASUREMENT_ID) printf '%s\n' "FB_MEASUREMENT_ID" "measurementId" ;;
    FB_DATABASE_URL) printf '%s\n' "FB_DATABASE_URL" "databaseURL" "databaseUrl" ;;
    FB_ANDROID_CLIENT_ID) printf '%s\n' "FB_ANDROID_CLIENT_ID" "androidClientId" ;;
    FB_IOS_CLIENT_ID) printf '%s\n' "FB_IOS_CLIENT_ID" "iosClientId" ;;
    FB_IOS_BUNDLE_ID) printf '%s\n' "FB_IOS_BUNDLE_ID" "iosBundleId" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

extract_dart_value() {
  local file="$1"
  local key="$2"
  LC_ALL=C LANG=C perl - "$file" "$key" <<'PERL'
use strict;
use warnings;

my ($file, $key) = @ARGV;
open my $fh, '<', $file or exit 0;
local $/;
my $text = <$fh>;

my @patterns = (
  qr/(?<![A-Za-z0-9_])\Q$key\E\s*[:=]\s*(?:const\s+)?['"]([^'"]*)['"]/s,
  qr/(?<![A-Za-z0-9_])['"]\Q$key\E['"]\s*[:=]\s*(?:const\s+)?['"]([^'"]*)['"]/s,
);

for my $pattern (@patterns) {
  if ($text =~ $pattern) {
    print $1;
    exit 0;
  }
}

exit 0;
PERL
}

extract_firebase_rules_path() {
  local file="$1"
  local service="$2"
  LC_ALL=C LANG=C perl - "$file" "$service" <<'PERL'
use strict;
use warnings;

my ($file, $service) = @ARGV;
open my $fh, '<', $file or exit 0;
local $/;
my $text = <$fh>;

my %patterns = (
  firestore => qr/"firestore"\s*:\s*\{.*?"rules"\s*:\s*"([^"]+)"/s,
  storage => qr/"storage"\s*:\s*\{.*?"rules"\s*:\s*"([^"]+)"/s,
);

my $pattern = $patterns{$service} or exit 0;
if ($text =~ $pattern) {
  print $1;
}
PERL
}

resolve_rules_path() {
  local service="$1"
  local default_path="$2"
  local path=""
  path="$(configured_rules_path "${service}")"

  if [[ -z "${path}" && -f "${default_path}" ]]; then
    path="${default_path}"
  fi

  printf '%s' "${path}"
}

configured_rules_path() {
  local service="$1"
  if [[ -f "firebase.json" ]]; then
    extract_firebase_rules_path "firebase.json" "${service}"
  fi
}

rules_has_public_access() {
  local file="$1"
  LC_ALL=C LANG=C perl - "$file" <<'PERL'
use strict;
use warnings;

my ($file) = @ARGV;
open my $fh, '<', $file or exit 0;
local $/;
my $text = <$fh>;

$text =~ s{/\*.*?\*/}{}gs;
$text =~ s{//.*$}{}mg;

my @patterns = (
  qr/allow\s+(?:read|write|create|update|delete|list|get|read\s*,\s*write|write\s*,\s*read)\s*:\s*if\s+true\b/is,
  qr/allow\s+(?:read|write|create|update|delete|list|get|read\s*,\s*write|write\s*,\s*read)\s*:\s*if\s+request\.auth\s*==\s*null\b/is,
  qr/allow\s+(?:read|write|create|update|delete|list|get|read\s*,\s*write|write\s*,\s*read)\s*:\s*if\s+null\b/is,
);

for my $pattern (@patterns) {
  if ($text =~ $pattern) {
    print "public\n";
    exit 0;
  }
}

exit 1;
PERL
}

rules_has_auth_guard() {
  local file="$1"
  LC_ALL=C LANG=C perl - "$file" <<'PERL'
use strict;
use warnings;

my ($file) = @ARGV;
open my $fh, '<', $file or exit 0;
local $/;
my $text = <$fh>;

$text =~ s{/\*.*?\*/}{}gs;
$text =~ s{//.*$}{}mg;

my @patterns = (
  qr/request\.auth\s*!=\s*null/is,
  qr/\bisSignedIn\s*\(/is,
  qr/\bisAuthenticated\s*\(/is,
  qr/\bhasVerifiedEmail\s*\(/is,
  qr/\bauthenticated\s*\(/is,
  qr/\bauthRequired\s*\(/is,
);

for my $pattern (@patterns) {
  if ($text =~ $pattern) {
    print "guard\n";
    exit 0;
  }
}

exit 1;
PERL
}

check_rules_file() {
  local label="$1"
  local path="$2"
  local service_marker="$3"

  if [[ -z "${path}" ]]; then
    echo "[FAIL] ${label} rules are not configured."
    return 1
  fi

  if [[ ! -f "${path}" ]]; then
    echo "[FAIL] ${label} rules file is configured as ${path}, but the file is missing."
    return 1
  fi

  local missing_markers=()
  if ! grep -Eq "rules_version[[:space:]]*=[[:space:]]*'2'" "${path}"; then
    missing_markers+=("rules_version = '2'")
  fi
  if ! grep -Eq "${service_marker}" "${path}"; then
    missing_markers+=("${label} service declaration")
  fi

  if [[ ${#missing_markers[@]} -gt 0 ]]; then
    echo "[FAIL] ${label} rules file ${path} is present but missing: ${missing_markers[*]}"
    return 1
  fi

  if rules_has_public_access "${path}" >/dev/null; then
    echo "[FAIL] ${label} rules file ${path} contains an obviously public allow rule."
    return 1
  fi

  if rules_has_auth_guard "${path}" >/dev/null; then
    echo "[PASS] ${label} rules file is present and includes an auth-based access guard: ${path}"
    return 0
  fi

  echo "[WARN] ${label} rules file ${path} is present and not obviously public, but no standard auth guard pattern was detected."
  return 0
}

required_vars=(
  FB_API_KEY
  FB_APP_ID
  FB_MESSAGING_SENDER_ID
  FB_PROJECT_ID
)

missing_required=()
for key in "${required_vars[@]}"; do
  if [[ -z "$(get_value "${key}")" ]]; then
    missing_required+=("${key}")
  fi
done

project_id="$(get_value FB_PROJECT_ID)"
auth_domain="$(get_value FB_AUTH_DOMAIN)"
storage_bucket="$(get_value FB_STORAGE_BUCKET)"

echo "ARM Firebase compatibility check"
echo "Directory: ${PROJECT_DIR}"
echo "Env file: ${ENV_FILE}"
if [[ -n "${DART_FILE}" ]]; then
  echo "Dart file: ${DART_FILE}"
else
  echo "Dart file: (none detected)"
fi
echo

failure_count=0

if [[ ${#missing_required[@]} -gt 0 ]]; then
  echo "[FAIL] Missing required Firebase config values: ${missing_required[*]}"
  echo "Add them to ${ENV_FILE}, export them in the shell, or provide a Dart options file before rerunning."
  failure_count=$((failure_count + 1))
else
  echo "[PASS] Required Firebase config values are present."
  echo "       projectId: ${project_id}"
fi

if [[ -n "${project_id}" && ! "${project_id}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "[WARN] FB_PROJECT_ID does not look like a slug-style Firebase project id."
fi

if [[ -n "${auth_domain}" ]]; then
  echo "[PASS] FB_AUTH_DOMAIN is set: ${auth_domain}"
else
  echo "[WARN] FB_AUTH_DOMAIN is missing. Web sign-in may be incomplete without it."
fi

if [[ -n "${storage_bucket}" ]]; then
  echo "[PASS] FB_STORAGE_BUCKET is set: ${storage_bucket}"
else
  echo "[WARN] FB_STORAGE_BUCKET is missing. Screenshot/evidence storage support will be limited."
fi

configured_firestore_rules_path="$(configured_rules_path "firestore")"
configured_storage_rules_path="$(configured_rules_path "storage")"
firestore_rules_path="$(resolve_rules_path "firestore" "firestore.rules")"
storage_rules_path="$(resolve_rules_path "storage" "storage.rules")"

echo
if [[ -f "firebase.json" ]]; then
  if [[ -n "${configured_firestore_rules_path}" ]]; then
    echo "[PASS] firebase.json declares Firestore rules at: ${configured_firestore_rules_path}"
  else
    echo "[FAIL] firebase.json does not declare a Firestore rules path."
    failure_count=$((failure_count + 1))
  fi

  if [[ -n "${configured_storage_rules_path}" ]]; then
    echo "[PASS] firebase.json declares Storage rules at: ${configured_storage_rules_path}"
  elif [[ -n "${storage_bucket}" ]]; then
    echo "[FAIL] firebase.json does not declare a Storage rules path even though FB_STORAGE_BUCKET is set."
    failure_count=$((failure_count + 1))
  else
    echo "[WARN] firebase.json does not declare Storage rules. That is acceptable only if this project does not use Cloud Storage for ARM evidence."
  fi
else
  echo "[WARN] firebase.json is missing. Falling back to default rule filenames only."
fi

echo
if ! check_rules_file "Firestore" "${firestore_rules_path}" "service[[:space:]]+cloud\\.firestore"; then
  failure_count=$((failure_count + 1))
fi

if [[ -n "${storage_bucket}" || -n "${storage_rules_path}" ]]; then
  if ! check_rules_file "Storage" "${storage_rules_path}" "service[[:space:]]+firebase\\.storage"; then
    failure_count=$((failure_count + 1))
  fi
else
  echo "[WARN] Storage rules were not checked because no storage bucket or storage rules file was detected."
fi

echo
echo "Compatibility summary:"
if [[ ${failure_count} -eq 0 ]]; then
  echo " - Core Firebase client config is complete."
  echo " - Required rule files are present and not obviously public."
else
  echo " - One or more required Firebase config or rules checks failed."
fi
echo " - ARM web sign-in support is best with FB_AUTH_DOMAIN present."
echo " - ARM screenshot/evidence support is best with FB_STORAGE_BUCKET plus locked-down Storage rules."

if [[ ${failure_count} -gt 0 ]]; then
  exit 1
fi
