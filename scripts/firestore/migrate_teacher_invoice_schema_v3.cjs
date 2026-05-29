#!/usr/bin/env node

const APPLY = process.argv.includes('--apply');
const projectArg = process.argv.find((arg) => arg.startsWith('--project='));
const projectId = projectArg ? projectArg.split('=')[1] : undefined;
const BATCH_LIMIT = 450;

const DEFAULTS = {
  agencyName: 'Axis Education Centre',
  addressLine1: '9 King Albert Park #02-08',
  addressLine2: 'Singapore 598332',
  phoneNum: '80626728',
  email: 'axiseducationcentre@gmail.com',
};

function usage() {
  console.log(
    [
      'Usage:',
      '  node scripts/firestore/migrate_teacher_invoice_schema_v3.cjs [--apply] [--project=<gcp-project-id>]',
      '',
      'Default mode is dry-run (no writes). Add --apply to commit updates.',
    ].join('\n'),
  );
}

if (process.argv.includes('--help')) {
  usage();
  process.exit(0);
}

function parseMoney(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function parseQuantity(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.trunc(parsed) : 0;
}

function normalizeEntries(entries) {
  if (!Array.isArray(entries)) return [];
  return entries.map((entry) => ({
    amt: parseMoney(entry?.amt),
    desc: String(entry?.desc ?? ''),
    qty: parseQuantity(entry?.qty),
    rate: parseMoney(entry?.rate),
  }));
}

function normalizeString(value, fallback = '') {
  return typeof value === 'string' ? value : fallback;
}

function parseDashboardDate(raw) {
  if (typeof raw !== 'string') return null;
  const match = raw.trim().match(/^(\d{1,2})-(\d{1,2})-(\d{4})$/);
  if (!match) return null;

  const [, day, month, year] = match;
  const date = new Date(Number(year), Number(month) - 1, Number(day));
  return Number.isNaN(date.getTime()) ? null : date;
}

function formatDashboardDate(date) {
  const day = String(date.getDate()).padStart(2, '0');
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const year = String(date.getFullYear());
  return `${day}-${month}-${year}`;
}

function deriveDueDateFormatted(data) {
  const current = normalizeString(data.dueDateFormatted);
  if (current.trim() !== '') return current;

  const invoiceDate = parseDashboardDate(data.invoiceDateFormatted);
  if (invoiceDate != null) {
    const dueDate = new Date(invoiceDate);
    dueDate.setDate(dueDate.getDate() + 14);
    return formatDashboardDate(dueDate);
  }

  return '';
}

function normalizeTeacherInvoice(data, invoiceId, FieldValue) {
  return {
    invoiceType: 'teacher',
    invoiceId,
    agencyName: normalizeString(data.agencyName, DEFAULTS.agencyName),
    addressLine1: normalizeString(data.addressLine1, DEFAULTS.addressLine1),
    addressLine2: normalizeString(data.addressLine2, DEFAULTS.addressLine2),
    phoneNum: normalizeString(data.phoneNum, DEFAULTS.phoneNum),
    email: normalizeString(data.email, DEFAULTS.email),
    amtDue: parseMoney(data.amtDue),
    teacherName: normalizeString(data.teacherName),
    address: normalizeString(data.address),
    invoiceDateFormatted: normalizeString(data.invoiceDateFormatted),
    dueDateFormatted: deriveDueDateFormatted(data),
    invoiceStatus: normalizeString(data.invoiceStatus, 'pendingBilling'),
    entries: normalizeEntries(data.entries),
    schemaVersion: 3,
    migratedAt: new Date().toISOString(),
    adminName: FieldValue.delete(),
    paidDateFormatted: FieldValue.delete(),
    terms: FieldValue.delete(),
  };
}

async function main() {
  const admin = require('firebase-admin');
  const { FieldValue } = require('firebase-admin/firestore');

  const initOptions = projectId ? { projectId } : {};
  admin.initializeApp(initOptions);
  const db = admin.firestore();

  const invoicesRef = db
    .collection('global')
    .doc('archives')
    .collection('invoices');
  const invoicesSnap = await invoicesRef.where('invoiceType', '==', 'teacher').get();

  console.log(
    `[teacher-invoice-v3] scanned ${invoicesSnap.size} teacher invoice documents (apply=${APPLY}).`,
  );

  let scanned = 0;
  let updated = 0;
  let skipped = 0;
  let batch = db.batch();
  let batchOps = 0;

  for (const doc of invoicesSnap.docs) {
    scanned += 1;
    const data = doc.data() || {};
    const payload = normalizeTeacherInvoice(data, doc.id, FieldValue);

    const unchanged =
      JSON.stringify({
        invoiceType: data.invoiceType ?? 'teacher',
        invoiceId: data.invoiceId ?? doc.id,
        agencyName: data.agencyName ?? DEFAULTS.agencyName,
        addressLine1: data.addressLine1 ?? DEFAULTS.addressLine1,
        addressLine2: data.addressLine2 ?? DEFAULTS.addressLine2,
        phoneNum: data.phoneNum ?? DEFAULTS.phoneNum,
        email: data.email ?? DEFAULTS.email,
        amtDue: parseMoney(data.amtDue),
        teacherName: normalizeString(data.teacherName),
        address: normalizeString(data.address),
        invoiceDateFormatted: normalizeString(data.invoiceDateFormatted),
        dueDateFormatted: deriveDueDateFormatted(data),
        invoiceStatus: normalizeString(data.invoiceStatus, 'pendingBilling'),
        entries: normalizeEntries(data.entries),
        schemaVersion: data.schemaVersion ?? 3,
      }) ===
      JSON.stringify({
        invoiceType: payload.invoiceType,
        invoiceId: payload.invoiceId,
        agencyName: payload.agencyName,
        addressLine1: payload.addressLine1,
        addressLine2: payload.addressLine2,
        phoneNum: payload.phoneNum,
        email: payload.email,
        amtDue: payload.amtDue,
        teacherName: payload.teacherName,
        address: payload.address,
        invoiceDateFormatted: payload.invoiceDateFormatted,
        dueDateFormatted: payload.dueDateFormatted,
        invoiceStatus: payload.invoiceStatus,
        entries: payload.entries,
        schemaVersion: 3,
      }) &&
      data.adminName == null &&
      data.paidDateFormatted == null &&
      data.terms == null;

    if (unchanged) {
      skipped += 1;
      continue;
    }

    if (APPLY) {
      batch.update(doc.ref, payload);
      batchOps += 1;
      if (batchOps >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        batchOps = 0;
      }
    }

    updated += 1;
  }

  if (APPLY && batchOps > 0) {
    await batch.commit();
  }

  console.log(
    `[teacher-invoice-v3] done. scanned=${scanned} updated=${updated} skipped=${skipped} apply=${APPLY}`,
  );
}

main().catch((error) => {
  console.error('[teacher-invoice-v3] failed:', error);
  process.exit(1);
});
