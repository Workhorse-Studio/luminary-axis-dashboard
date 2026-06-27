#!/usr/bin/env node

const { execFileSync } = require('node:child_process');

const APPLY = process.argv.includes('--apply');
const projectArg = process.argv.find((arg) => arg.startsWith('--project='));
const DEFAULT_PROJECT_ID = 'luminary-axis-dashboard';
let projectId =
  projectArg?.split('=')[1] ?? process.env.FIRESTORE_PROJECT_ID ?? DEFAULT_PROJECT_ID;
const PAGE_SIZE = 200;

function usage() {
  console.log(
    [
      'Usage:',
      '  node scripts/firestore/align_teacher_user_schema_v2.cjs [--apply] [--project=<gcp-project-id>]',
      '',
      'Default mode is dry-run (no writes). Add --apply to commit updates.',
      '',
      'What it does:',
      "  - scans users/* documents with role == 'teacher'",
      '  - normalizes teacher docs to match DashboardUI/lib/schemas/teacher_data.dart',
      '  - fills agencyName / agencyContact / agencyEmail / agencyAddress',
      '  - keeps legacy addressLine1 / addressLine2 / phoneNum aliases in sync',
      '  - normalizes classes, offeredClassTemplates, and invoiceIds types',
      '',
      'Auth:',
      '  1. Set FIRESTORE_ACCESS_TOKEN directly, or',
      '  2. Authenticate with gcloud ADC and let the script call:',
      '       gcloud auth application-default print-access-token',
    ].join('\n'),
  );
}

if (process.argv.includes('--help')) {
  usage();
  process.exit(0);
}

function normalizeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function normalizeStringArray(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((entry) => normalizeString(entry))
    .filter((entry) => entry !== '');
}

function normalizeTeacherInvoiceIds(raw) {
  if (raw == null || typeof raw !== 'object' || Array.isArray(raw)) {
    return {};
  }

  const normalized = {};
  for (const [monthId, invoiceId] of Object.entries(raw)) {
    const monthKey = normalizeString(monthId);
    const invoiceValue = normalizeString(invoiceId);
    if (monthKey !== '' && invoiceValue !== '') {
      normalized[monthKey] = invoiceValue;
    }
  }
  return normalized;
}

function splitAgencyAddress(address) {
  const lines = normalizeString(address)
    .split(/\r?\n/g)
    .map((line) => line.trim())
    .filter((line) => line !== '');

  return {
    agencyAddress: lines.join('\n'),
    addressLine1: lines[0] ?? '',
    addressLine2: lines.slice(1).join(', '),
  };
}

function buildLegacyAddress(data) {
  return [normalizeString(data.addressLine1), normalizeString(data.addressLine2)]
    .filter((line) => line !== '')
    .join('\n');
}

function normalizeTeacherDocument(data) {
  const name = normalizeString(data.name);
  const email = normalizeString(data.email);
  const agencyName = normalizeString(data.agencyName) || name;
  const agencyContact =
    normalizeString(data.agencyContact) || normalizeString(data.phoneNum);
  const agencyEmail =
    normalizeString(data.agencyEmail) || email;
  const agencyAddressSource =
    normalizeString(data.agencyAddress) || buildLegacyAddress(data);
  const addressFields = splitAgencyAddress(agencyAddressSource);

  return {
    role: 'teacher',
    name,
    email,
    classes: normalizeStringArray(data.classes ?? data.classIds),
    offeredClassTemplates: normalizeStringArray(data.offeredClassTemplates),
    invoiceIds: normalizeTeacherInvoiceIds(data.invoiceIds),
    agencyName,
    agencyContact,
    agencyEmail,
    agencyAddress: addressFields.agencyAddress,
    addressLine1: addressFields.addressLine1,
    addressLine2: addressFields.addressLine2,
    phoneNum: agencyContact,
  };
}

function deepEqual(a, b) {
  if (a === b) return true;

  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b)) return false;
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i += 1) {
      if (!deepEqual(a[i], b[i])) return false;
    }
    return true;
  }

  if (a && b && typeof a === 'object' && typeof b === 'object') {
    const aKeys = Object.keys(a).sort();
    const bKeys = Object.keys(b).sort();
    if (!deepEqual(aKeys, bKeys)) return false;
    return aKeys.every((key) => deepEqual(a[key], b[key]));
  }

  return false;
}

function decodeFirestoreValue(value) {
  if (!value || typeof value !== 'object') return null;
  if ('stringValue' in value) return value.stringValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return Number(value.doubleValue);
  if ('booleanValue' in value) return Boolean(value.booleanValue);
  if ('timestampValue' in value) return value.timestampValue;
  if ('nullValue' in value) return null;
  if ('referenceValue' in value) return value.referenceValue;
  if ('arrayValue' in value) {
    return (value.arrayValue.values ?? []).map(decodeFirestoreValue);
  }
  if ('mapValue' in value) {
    return decodeFirestoreFields(value.mapValue.fields ?? {});
  }
  return null;
}

function decodeFirestoreFields(fields) {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, decodeFirestoreValue(value)]),
  );
}

function encodeFirestoreValue(value) {
  if (value === null) return { nullValue: null };
  if (Array.isArray(value)) {
    return value.length === 0
      ? { arrayValue: {} }
      : { arrayValue: { values: value.map(encodeFirestoreValue) } };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (typeof value === 'object') {
    const fields = Object.fromEntries(
      Object.entries(value).map(([key, entry]) => [key, encodeFirestoreValue(entry)]),
    );
    return Object.keys(fields).length === 0 ? { mapValue: {} } : { mapValue: { fields } };
  }
  throw new TypeError(`Unsupported Firestore value: ${value}`);
}

function encodeFirestoreFields(fields) {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, encodeFirestoreValue(value)]),
  );
}

function resolveProjectId() {
  if (!projectId || projectId === '(unset)') {
    projectId = DEFAULT_PROJECT_ID;
  }
}

function resolveAccessToken() {
  if (process.env.FIRESTORE_ACCESS_TOKEN) {
    return process.env.FIRESTORE_ACCESS_TOKEN;
  }

  const commands = [
    ['gcloud', ['auth', 'print-access-token']],
    ['gcloud', ['auth', 'application-default', 'print-access-token']],
  ];

  for (const [command, args] of commands) {
    try {
      const token = execFileSync(command, args, {
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'ignore'],
      }).trim();
      if (token) return token;
    } catch (_) {
      // Try the next auth source.
    }
  }

  throw new Error(
    'Unable to resolve a Firestore access token. Set FIRESTORE_ACCESS_TOKEN or authenticate with gcloud.',
  );
}

async function firestoreRequest(url, init, accessToken) {
  const response = await fetch(url, {
    ...init,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      ...(init?.headers ?? {}),
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Firestore request failed (${response.status}): ${body}`);
  }

  return response;
}

function buildUsersListUrl(pageToken = '') {
  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users`,
  );
  url.searchParams.set('pageSize', String(PAGE_SIZE));
  for (const field of [
    'role',
    'name',
    'email',
    'classes',
    'classIds',
    'offeredClassTemplates',
    'invoiceIds',
    'agencyName',
    'agencyContact',
    'agencyEmail',
    'agencyAddress',
    'addressLine1',
    'addressLine2',
    'phoneNum',
  ]) {
    url.searchParams.append('mask.fieldPaths', field);
  }
  if (pageToken) {
    url.searchParams.set('pageToken', pageToken);
  }
  return url.toString();
}

function buildPatchUrl(docName, patch) {
  const url = new URL(`https://firestore.googleapis.com/v1/${docName}`);
  url.searchParams.set('currentDocument.exists', 'true');
  for (const field of Object.keys(patch)) {
    url.searchParams.append('updateMask.fieldPaths', field);
  }
  return url.toString();
}

async function main() {
  const unknownArgs = process.argv.slice(2).filter(
    (arg) => arg !== '--apply' && !arg.startsWith('--project='),
  );
  if (unknownArgs.length > 0) {
    console.error(`Unknown argument(s): ${unknownArgs.join(', ')}`);
    usage();
    process.exit(1);
  }

  resolveProjectId();
  const accessToken = resolveAccessToken();

  console.log(
    `[teacher-user-schema-v2] project=${projectId} apply=${APPLY}`,
  );

  let scanned = 0;
  let teacherDocs = 0;
  let updated = 0;
  let unchanged = 0;
  let warnings = 0;
  let pageToken = '';

  do {
    const response = await firestoreRequest(
      buildUsersListUrl(pageToken),
      { method: 'GET' },
      accessToken,
    );
    const payload = await response.json();
    const documents = payload.documents ?? [];

    for (const doc of documents) {
      scanned += 1;
      const data = decodeFirestoreFields(doc.fields ?? {});
      if (normalizeString(data.role) !== 'teacher') {
        continue;
      }

      teacherDocs += 1;
      const normalized = normalizeTeacherDocument(data);
      const patch = Object.fromEntries(
        Object.entries(normalized).filter(([key, value]) => !deepEqual(data[key], value)),
      );

      if (normalized.name === '' || normalized.email === '') {
        warnings += 1;
        console.log(
          `[warn] ${doc.name.split('/').pop()} has blank required fields after normalization: name=${JSON.stringify(
            normalized.name,
          )} email=${JSON.stringify(normalized.email)}`,
        );
      }

      if (Object.keys(patch).length === 0) {
        unchanged += 1;
        continue;
      }

      if (APPLY) {
        await firestoreRequest(
          buildPatchUrl(doc.name, patch),
          {
            method: 'PATCH',
            body: JSON.stringify({
              name: doc.name,
              fields: encodeFirestoreFields(patch),
            }),
          },
          accessToken,
        );
        console.log(
          `[teacher-user-schema-v2] patched ${doc.name.split('/').pop()} fields=${Object.keys(
            patch,
          ).join(',')}`,
        );
      } else {
        console.log(
          `[teacher-user-schema-v2] would patch ${doc.name.split('/').pop()} fields=${Object.keys(
            patch,
          ).join(',')}`,
        );
      }

      updated += 1;
    }

    pageToken = payload.nextPageToken ?? '';
  } while (pageToken);

  console.log(
    `[teacher-user-schema-v2] done. scanned=${scanned} teachers=${teacherDocs} updated=${updated} unchanged=${unchanged} warnings=${warnings} apply=${APPLY}`,
  );
}

main().catch((error) => {
  console.error('[teacher-user-schema-v2] failed:', error);
  process.exit(1);
});
