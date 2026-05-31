# Firestore Invoice Schema Migration Scripts

These scripts migrate existing invoice-related Firestore documents to match the current student/teacher invoice schemas used in `lib/schemas/student_invoice_data.dart` and `lib/schemas/teacher_invoice_data.dart`.

## Prerequisites

1. Node.js 18+
2. Install dependency once:

```bash
npm install firebase-admin
```

3. Authenticate with Application Default Credentials or set a service account key:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json
```

Optional explicit project override:

```bash
--project=<your-gcp-project-id>
```

## Scripts

### 1) Invoice document migration

Dry-run:

```bash
node scripts/firestore/migrate_invoice_documents.cjs
```

Apply:

```bash
node scripts/firestore/migrate_invoice_documents.cjs --apply
```

What it does:
- Normalizes `global/archives/invoices/*` docs by `invoiceType`
- Enforces required fields for student and teacher invoice documents
- Removes irrelevant cross-type fields
- Sets `schemaVersion: 2` and `migratedAt`

### 2) User invoice reference normalization

Dry-run:

```bash
node scripts/firestore/migrate_user_invoice_references.cjs
```

Apply:

```bash
node scripts/firestore/migrate_user_invoice_references.cjs --apply
```

What it does:
- For students: normalizes `users/{id}.invoiceIds` to `List<String|null>`
- For teachers/admins: normalizes `users/{id}.invoiceIds` to `Map<String, String>`

### 3) Teacher invoice schema v3 migration

Dry-run:

```bash
bash scripts/firestore/migrate_teacher_invoice_schema_v3.sh
```

Apply:

```bash
bash scripts/firestore/migrate_teacher_invoice_schema_v3.sh --apply
```

What it does:
- Upgrades `global/archives/invoices/*` teacher docs from the old `adminName`/`terms`/`paidDateFormatted` shape to the current `agencyName`/`addressLine1`/`addressLine2`/`phoneNum`/`email`/`dueDateFormatted` shape
- Uses standard Axis contact defaults for the new teacher invoice issuer fields
- Derives `dueDateFormatted` as `invoiceDateFormatted + 14 days` when it is missing
- Removes the old teacher-only fields and sets `schemaVersion: 3` plus `migratedAt`
- Uses the Firestore REST API directly with `bash` and `curl`

## Recommended execution order

1. `migrate_invoice_documents.cjs` (dry-run)
2. `migrate_user_invoice_references.cjs` (dry-run)
3. `migrate_teacher_invoice_schema_v3.cjs` (dry-run)
4. Re-run the needed scripts with `--apply`
