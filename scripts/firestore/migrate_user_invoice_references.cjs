#!/usr/bin/env node

const APPLY = process.argv.includes('--apply');
const projectArg = process.argv.find((arg) => arg.startsWith('--project='));
const projectId = projectArg ? projectArg.split('=')[1] : undefined;
const BATCH_LIMIT = 450;

function usage() {
  console.log(
    [
      'Usage:',
      '  node scripts/firestore/migrate_user_invoice_references.cjs [--apply] [--project=<gcp-project-id>]',
      '',
      'Default mode is dry-run (no writes). Add --apply to commit updates.',
    ].join('\n'),
  );
}

if (process.argv.includes('--help')) {
  usage();
  process.exit(0);
}

function normalizeStudentInvoiceIds(raw) {
  if (!Array.isArray(raw)) return [];
  return raw.map((entry) => (typeof entry === 'string' ? entry : null));
}

function normalizeTeacherInvoiceIds(raw) {
  if (raw == null || typeof raw !== 'object' || Array.isArray(raw)) {
    return {};
  }

  const normalized = {};
  for (const [monthId, invoiceId] of Object.entries(raw)) {
    if (typeof monthId !== 'string' || monthId.trim() === '') continue;
    if (typeof invoiceId === 'string' && invoiceId.trim() !== '') {
      normalized[monthId] = invoiceId;
    }
  }
  return normalized;
}

async function main() {
  const admin = require('firebase-admin');

  const initOptions = projectId ? { projectId } : {};
  admin.initializeApp(initOptions);
  const db = admin.firestore();

  const usersRef = db.collection('users');
  const [studentsSnap, staffSnap] = await Promise.all([
    usersRef.where('role', '==', 'student').get(),
    usersRef.where('role', 'in', ['teacher', 'admin']).get(),
  ]);

  console.log(
    `[user-ref-migration] scanned students=${studentsSnap.size}, teachers/admin=${staffSnap.size} (apply=${APPLY}).`,
  );

  let scanned = 0;
  let updated = 0;
  let batch = db.batch();
  let batchOps = 0;

  for (const doc of studentsSnap.docs) {
    scanned += 1;
    const data = doc.data() || {};
    const normalized = normalizeStudentInvoiceIds(data.invoiceIds);

    const unchanged = JSON.stringify(normalized) === JSON.stringify(data.invoiceIds ?? []);
    if (unchanged) continue;

    if (APPLY) {
      batch.update(doc.ref, { invoiceIds: normalized });
      batchOps += 1;
      if (batchOps >= BATCH_LIMIT) {
        await batch.commit();
        batch = db.batch();
        batchOps = 0;
      }
    }
    updated += 1;
  }

  for (const doc of staffSnap.docs) {
    scanned += 1;
    const data = doc.data() || {};
    const normalized = normalizeTeacherInvoiceIds(data.invoiceIds);

    const unchanged = JSON.stringify(normalized) === JSON.stringify(data.invoiceIds ?? {});
    if (unchanged) continue;

    if (APPLY) {
      batch.update(doc.ref, { invoiceIds: normalized });
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
    `[user-ref-migration] done. scanned=${scanned} updated=${updated} apply=${APPLY}`,
  );
}

main().catch((error) => {
  console.error('[user-ref-migration] failed:', error);
  process.exit(1);
});
