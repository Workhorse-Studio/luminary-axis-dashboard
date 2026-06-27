#!/usr/bin/env node

const { execFileSync } = require('node:child_process');

const APPLY = process.argv.includes('--apply');
const projectArg = process.argv.find((arg) => arg.startsWith('--project='));
const DEFAULT_PROJECT_ID = 'luminary-axis-dashboard';
let projectId =
  projectArg?.split('=')[1] ?? process.env.FIRESTORE_PROJECT_ID ?? DEFAULT_PROJECT_ID;
const PAGE_SIZE = 200;

const USER_REMOVED_FIELDS = ['addressLine1', 'addressLine2', 'phoneNum', 'classIds'];
const INVOICE_REMOVED_FIELDS = [
  'teacherName',
  'address',
  'addressLine1',
  'addressLine2',
  'phoneNum',
  'email',
  'adminName',
  'terms',
  'paidDateFormatted',
  'schemaVersion',
  'migratedAt',
];

function usage() {
  console.log(
    [
      'Usage:',
      '  node scripts/firestore/prune_teacher_schema_legacy_fields_v1.cjs [--apply] [--project=<gcp-project-id>]',
      '',
      'Default mode is dry-run (no writes). Add --apply to commit updates.',
      '',
      'What it does:',
      "  - scans users/* documents with role == 'teacher'",
      '  - keeps only the current teacher schema fields used by TeacherData',
      "  - scans global/archives/invoices/* documents with invoiceType == 'teacher'",
      '  - keeps only the current teacher invoice schema fields used by TeacherInvoiceData',
      '  - deletes only the specific removed legacy fields; unrelated metadata is left untouched',
      '',
      'Auth:',
      '  1. Set FIRESTORE_ACCESS_TOKEN directly, or',
      '  2. Authenticate with gcloud and let the script call:',
      '       gcloud auth print-access-token',
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
  return raw.map(normalizeString).filter((entry) => entry !== '');
}

function normalizeMap(raw) {
  if (raw == null || typeof raw !== 'object' || Array.isArray(raw)) {
    return {};
  }

  const normalized = {};
  for (const [key, value] of Object.entries(raw)) {
    const normalizedKey = normalizeString(key);
    const normalizedValue = normalizeString(value);
    if (normalizedKey !== '' && normalizedValue !== '') {
      normalized[normalizedKey] = normalizedValue;
    }
  }
  return normalized;
}

function buildMultilineAddress(...parts) {
  return parts
    .map(normalizeString)
    .filter((line) => line !== '')
    .join('\n');
}

function normalizeTeacherUser(data) {
  const name = normalizeString(data.name);
  const email = normalizeString(data.email);

  return {
    role: 'teacher',
    name,
    email,
    classes: normalizeStringArray(data.classes ?? data.classIds),
    offeredClassTemplates: normalizeStringArray(data.offeredClassTemplates),
    invoiceIds: normalizeMap(data.invoiceIds),
    agencyName: normalizeString(data.agencyName) || name,
    agencyContact:
      normalizeString(data.agencyContact) || normalizeString(data.phoneNum),
    agencyEmail:
      normalizeString(data.agencyEmail) || email,
    agencyAddress:
      normalizeString(data.agencyAddress) ||
      buildMultilineAddress(data.addressLine1, data.addressLine2),
  };
}

function normalizeInvoiceEntries(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.map((entry) => ({
    amt: Number(entry?.amt ?? 0),
    desc: String(entry?.desc ?? ''),
    qty: Math.trunc(Number(entry?.qty ?? 0)),
    rate: Number(entry?.rate ?? 0),
  }));
}

function normalizeTeacherInvoice(data, docId) {
  return {
    invoiceType: 'teacher',
    invoiceId: normalizeString(data.invoiceId) || docId,
    agencyName:
      normalizeString(data.agencyName) || normalizeString(data.teacherName),
    agencyContact:
      normalizeString(data.agencyContact) || normalizeString(data.phoneNum),
    agencyEmail:
      normalizeString(data.agencyEmail) || normalizeString(data.email),
    agencyAddress:
      normalizeString(data.agencyAddress) ||
      buildMultilineAddress(data.addressLine1, data.addressLine2),
    amtDue: Number(data.amtDue ?? 0),
    invoiceDateFormatted: normalizeString(data.invoiceDateFormatted),
    dueDateFormatted:
      normalizeString(data.dueDateFormatted) ||
      normalizeString(data.paidDateFormatted),
    invoiceStatus: normalizeString(data.invoiceStatus) || 'pendingBilling',
    entries: normalizeInvoiceEntries(data.entries),
  };
}

function deepEqual(a, b) {
  if (a === b) return true;

  if (Array.isArray(a) || Array.isArray(b)) {
    if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) {
      return false;
    }
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

  for (const args of [
    ['auth', 'print-access-token'],
    ['auth', 'application-default', 'print-access-token'],
  ]) {
    try {
      const token = execFileSync('gcloud', args, {
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

function buildListUrl(path, fieldPaths, pageToken = '') {
  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${path}`,
  );
  url.searchParams.set('pageSize', String(PAGE_SIZE));
  for (const field of fieldPaths) {
    url.searchParams.append('mask.fieldPaths', field);
  }
  if (pageToken) {
    url.searchParams.set('pageToken', pageToken);
  }
  return url.toString();
}

function buildPatchUrl(docName, fieldPaths) {
  const url = new URL(`https://firestore.googleapis.com/v1/${docName}`);
  url.searchParams.set('currentDocument.exists', 'true');
  for (const field of fieldPaths) {
    url.searchParams.append('updateMask.fieldPaths', field);
  }
  return url.toString();
}

async function pruneDocument({
  doc,
  data,
  canonical,
  removedFields,
  accessToken,
  label,
}) {
  const patch = Object.fromEntries(
    Object.entries(canonical).filter(([key, value]) => !deepEqual(data[key], value)),
  );
  const deletions = removedFields.filter((field) => Object.hasOwn(data, field));
  const fieldPaths = [...new Set([...Object.keys(patch), ...deletions])];

  if (fieldPaths.length === 0) {
    return false;
  }

  if (APPLY) {
    await firestoreRequest(
      buildPatchUrl(doc.name, fieldPaths),
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
      `[${label}] patched ${doc.name.split('/').pop()} fields=${fieldPaths.join(',')}`,
    );
  } else {
    console.log(
      `[${label}] would patch ${doc.name.split('/').pop()} fields=${fieldPaths.join(',')}`,
    );
  }

  return true;
}

async function processTeacherUsers(accessToken) {
  let scanned = 0;
  let matched = 0;
  let updated = 0;
  let unchanged = 0;
  let pageToken = '';

  do {
    const response = await firestoreRequest(
      buildListUrl(
        'users',
        [
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
          ...USER_REMOVED_FIELDS,
        ],
        pageToken,
      ),
      { method: 'GET' },
      accessToken,
    );
    const payload = await response.json();

    for (const doc of payload.documents ?? []) {
      scanned += 1;
      const data = decodeFirestoreFields(doc.fields ?? {});
      if (normalizeString(data.role) !== 'teacher') {
        continue;
      }

      matched += 1;
      const didUpdate = await pruneDocument({
        doc,
        data,
        canonical: normalizeTeacherUser(data),
        removedFields: USER_REMOVED_FIELDS,
        accessToken,
        label: 'teacher-user-prune',
      });
      if (didUpdate) {
        updated += 1;
      } else {
        unchanged += 1;
      }
    }

    pageToken = payload.nextPageToken ?? '';
  } while (pageToken);

  return { scanned, matched, updated, unchanged };
}

async function processTeacherInvoices(accessToken) {
  let scanned = 0;
  let matched = 0;
  let updated = 0;
  let unchanged = 0;
  let pageToken = '';

  do {
    const response = await firestoreRequest(
      buildListUrl(
        'global/archives/invoices',
        [
          'invoiceType',
          'invoiceId',
          'agencyName',
          'agencyContact',
          'agencyEmail',
          'agencyAddress',
          'amtDue',
          'invoiceDateFormatted',
          'dueDateFormatted',
          'invoiceStatus',
          'entries',
          ...INVOICE_REMOVED_FIELDS,
        ],
        pageToken,
      ),
      { method: 'GET' },
      accessToken,
    );
    const payload = await response.json();

    for (const doc of payload.documents ?? []) {
      scanned += 1;
      const data = decodeFirestoreFields(doc.fields ?? {});
      if (normalizeString(data.invoiceType) !== 'teacher') {
        continue;
      }

      matched += 1;
      const didUpdate = await pruneDocument({
        doc,
        data,
        canonical: normalizeTeacherInvoice(data, doc.name.split('/').pop()),
        removedFields: INVOICE_REMOVED_FIELDS,
        accessToken,
        label: 'teacher-invoice-prune',
      });
      if (didUpdate) {
        updated += 1;
      } else {
        unchanged += 1;
      }
    }

    pageToken = payload.nextPageToken ?? '';
  } while (pageToken);

  return { scanned, matched, updated, unchanged };
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

  console.log(`[teacher-schema-prune] project=${projectId} apply=${APPLY}`);

  const userSummary = await processTeacherUsers(accessToken);
  const invoiceSummary = await processTeacherInvoices(accessToken);

  console.log(
    `[teacher-schema-prune] done. userScanned=${userSummary.scanned} teacherUsers=${userSummary.matched} userUpdated=${userSummary.updated} userUnchanged=${userSummary.unchanged} invoiceScanned=${invoiceSummary.scanned} teacherInvoices=${invoiceSummary.matched} invoiceUpdated=${invoiceSummary.updated} invoiceUnchanged=${invoiceSummary.unchanged} apply=${APPLY}`,
  );
}

main().catch((error) => {
  console.error('[teacher-schema-prune] failed:', error);
  process.exit(1);
});
