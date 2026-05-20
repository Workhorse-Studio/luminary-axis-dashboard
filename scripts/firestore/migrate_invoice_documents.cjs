#!/usr/bin/env node

const APPLY = process.argv.includes('--apply');
const projectArg = process.argv.find((arg) => arg.startsWith('--project='));
const projectId = projectArg ? projectArg.split('=')[1] : undefined;
const BATCH_LIMIT = 450;

function usage() {
  console.log(
    [
      'Usage:',
      '  node scripts/firestore/migrate_invoice_documents.cjs [--apply] [--project=<gcp-project-id>]',
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

function normalizeStudentInvoice(data, invoiceId, FieldValue) {
  const normalized = {
    invoiceType: 'student',
    invoiceId,
    amtPayable: parseMoney(data.amtPayable),
    remarks: String(data.remarks ?? ''),
    parentName: String(data.parentName ?? ''),
    studentName: String(data.studentName ?? ''),
    address: String(data.address ?? ''),
    invoiceDateFormatted: String(data.invoiceDateFormatted ?? ''),
    terms: String(data.terms ?? ''),
    dueDateFormatted: String(data.dueDateFormatted ?? ''),
    invoiceStatus: String(data.invoiceStatus ?? 'pendingBilling'),
    entries: normalizeEntries(data.entries),
    schemaVersion: 2,
    migratedAt: new Date().toISOString(),
    amtDue: FieldValue.delete(),
    teacherName: FieldValue.delete(),
    adminName: FieldValue.delete(),
    paidDateFormatted: FieldValue.delete(),
  };

  return normalized;
}

function normalizeTeacherInvoice(data, invoiceId, FieldValue) {
  const normalized = {
    invoiceType: 'teacher',
    invoiceId,
    amtDue: parseMoney(data.amtDue),
    teacherName: String(data.teacherName ?? ''),
    adminName: String(data.adminName ?? ''),
    address: String(data.address ?? ''),
    invoiceDateFormatted: String(data.invoiceDateFormatted ?? ''),
    invoiceStatus: String(data.invoiceStatus ?? 'pendingBilling'),
    terms: String(data.terms ?? ''),
    paidDateFormatted: String(data.paidDateFormatted ?? ''),
    entries: normalizeEntries(data.entries),
    schemaVersion: 2,
    migratedAt: new Date().toISOString(),
    amtPayable: FieldValue.delete(),
    remarks: FieldValue.delete(),
    parentName: FieldValue.delete(),
    studentName: FieldValue.delete(),
    dueDateFormatted: FieldValue.delete(),
  };

  return normalized;
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

  const invoicesSnap = await invoicesRef.get();
  console.log(
    `[invoice-doc-migration] scanned ${invoicesSnap.size} invoice documents (apply=${APPLY}).`,
  );

  let scanned = 0;
  let updated = 0;
  let skipped = 0;
  let batch = db.batch();
  let batchOps = 0;

  for (const doc of invoicesSnap.docs) {
    scanned += 1;
    const data = doc.data() || {};
    const invoiceType = data.invoiceType;

    if (invoiceType !== 'student' && invoiceType !== 'teacher') {
      skipped += 1;
      console.log(
        `[skip] ${doc.id} has unsupported invoiceType=${JSON.stringify(invoiceType)}`,
      );
      continue;
    }

    const payload =
      invoiceType === 'student'
        ? normalizeStudentInvoice(data, doc.id, FieldValue)
        : normalizeTeacherInvoice(data, doc.id, FieldValue);

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
    `[invoice-doc-migration] done. scanned=${scanned} updated=${updated} skipped=${skipped} apply=${APPLY}`,
  );
}

main().catch((error) => {
  console.error('[invoice-doc-migration] failed:', error);
  process.exit(1);
});
