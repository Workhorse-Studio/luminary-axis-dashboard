import {createHash, createHmac, timingSafeEqual} from "node:crypto";

import {FieldValue, getFirestore} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import {defineSecret} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";

import {decodeCell, hashValue, parseFieldHashes} from "./codec.js";
import {mappingByTitle} from "./config.js";
import {syncEventDocumentPath} from "./identifiers.js";
import {
  CONTROL_HEADERS,
  READ_ONLY_HEADERS,
  type ManagedSheetConfig,
  type SheetEditPayload,
  type SheetEditResult,
  type SheetEditRow,
  type SyncConfig,
} from "./types.js";

export const sheetSyncWebhookSecret = defineSecret("SHEET_SYNC_WEBHOOK_SECRET");

function safeSignatureEquals(actual: string, expected: string): boolean {
  const actualBuffer = Buffer.from(actual, "hex");
  const expectedBuffer = Buffer.from(expected, "hex");
  return actualBuffer.length === expectedBuffer.length &&
    timingSafeEqual(actualBuffer, expectedBuffer);
}

function verifyRequest(rawBody: Buffer, signature: string, secret: string): boolean {
  const expected = createHmac("sha256", secret).update(rawBody).digest("hex");
  return safeSignatureEquals(signature, expected);
}

function docIdForRow(payload: SheetEditPayload, row: SheetEditRow): string {
  if (row.docId?.trim()) return row.docId.trim();
  return createHash("sha256")
    .update(`${payload.eventId}:${row.rowNumber}`)
    .digest("base64url")
    .slice(0, 20);
}

function documentPath(
  mapping: ManagedSheetConfig,
  docId: string,
  parentId?: string,
): string {
  let path = mapping.firestorePattern;
  if (path.includes("{parentId}")) {
    if (!parentId) throw new Error("parentId is required for this sheet");
    path = path.replace("{parentId}", parentId);
  }
  if (path.includes("{docId}")) return path.replace("{docId}", docId);
  return path;
}

async function processRow(
  payload: SheetEditPayload,
  mapping: ManagedSheetConfig,
  row: SheetEditRow,
): Promise<SheetEditResult> {
  const docId = docIdForRow(payload, row);
  const ref = getFirestore().doc(documentPath(mapping, docId, row.parentId));
  const current = await ref.get();

  if (row.deleteRequested) {
    if (!current.exists) return {rowNumber: row.rowNumber, docId, status: "DELETED"};
    const currentVersion = current.updateTime?.toDate().toISOString();
    if (row.version && currentVersion !== row.version) {
      return {
        rowNumber: row.rowNumber,
        docId,
        status: "CONFLICT: document changed before deletion",
        conflicts: ["*"],
      };
    }
    await ref.delete();
    return {rowNumber: row.rowNumber, docId, status: "DELETE QUEUED"};
  }

  if (!current.exists) {
    const data: Record<string, unknown> = {};
    for (const [field, raw] of Object.entries(row.values)) {
      if (field === "docId" || field === "parentId" || CONTROL_HEADERS.includes(field as never)) {
        continue;
      }
      const value = decodeCell(raw, undefined);
      if (value !== undefined) data[field] = value;
    }
    if (Object.keys(data).length === 0) {
      return {rowNumber: row.rowNumber, docId, status: "ERROR: new row has no fields"};
    }
    await ref.create(data);
    return {rowNumber: row.rowNumber, docId, status: "CREATE QUEUED"};
  }

  const currentData = current.data() ?? {};
  const baseHashes = parseFieldHashes(row.fieldHashes);
  const patch: Record<string, unknown> = {};
  const conflicts: string[] = [];
  const errors: string[] = [];
  const changedFields = [...new Set(row.changedHeaders)]
    .filter((field) => !READ_ONLY_HEADERS.has(field) && field !== "_delete");

  for (const field of changedFields) {
    const expectedBaseHash = baseHashes[field] ?? hashValue(undefined);
    if (hashValue(currentData[field]) !== expectedBaseHash) {
      conflicts.push(field);
      continue;
    }
    try {
      const value = decodeCell(row.values[field], currentData[field]);
      if (value !== undefined) patch[field] = value;
    } catch (error) {
      errors.push(`${field}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  if (Object.keys(patch).length > 0) await ref.update(patch);
  if (errors.length > 0) {
    return {rowNumber: row.rowNumber, docId, status: `ERROR: ${errors.join("; ")}`};
  }
  if (conflicts.length > 0) {
    return {
      rowNumber: row.rowNumber,
      docId,
      status: `CONFLICT: ${conflicts.join(", ")}`,
      conflicts,
    };
  }
  return {rowNumber: row.rowNumber, docId, status: "UPDATE QUEUED"};
}

function parsePayload(body: unknown): SheetEditPayload {
  if (!body || typeof body !== "object") throw new Error("Request body must be JSON");
  const payload = body as Partial<SheetEditPayload>;
  if (typeof payload.eventId !== "string" || !payload.eventId) throw new Error("eventId is required");
  if (typeof payload.timestamp !== "number") throw new Error("timestamp is required");
  if (typeof payload.spreadsheetId !== "string") throw new Error("spreadsheetId is required");
  if (typeof payload.sheetTitle !== "string") throw new Error("sheetTitle is required");
  if (!Array.isArray(payload.rows)) throw new Error("rows must be an array");
  return payload as SheetEditPayload;
}

export function createSheetEditWebhook(config: SyncConfig) {
  return onRequest(
    {
      region: config.region,
      serviceAccount: config.runtimeServiceAccount,
      secrets: [sheetSyncWebhookSecret],
      invoker: "public",
      timeoutSeconds: 60,
      memory: "256MiB",
      maxInstances: 5,
    },
    async (request, response) => {
      try {
        if (request.method !== "POST") {
          response.status(405).json({error: "POST required"});
          return;
        }
        const signature = request.header("x-sheet-sync-signature") ?? "";
        if (!verifyRequest(request.rawBody, signature, sheetSyncWebhookSecret.value().trim())) {
          response.status(401).json({error: "Invalid signature"});
          return;
        }

        const payload = parsePayload(request.body);
        if (Math.abs(Date.now() - payload.timestamp) > 5 * 60_000) {
          response.status(401).json({error: "Expired request"});
          return;
        }
        if (payload.spreadsheetId !== config.spreadsheetId) {
          response.status(403).json({error: "Unexpected spreadsheet"});
          return;
        }
        const mapping = mappingByTitle(config, payload.sheetTitle);
        if (!mapping) {
          response.status(404).json({error: "Sheet is not managed"});
          return;
        }

        const eventRef = getFirestore().doc(syncEventDocumentPath(payload.eventId));
        const prior = await eventRef.get();
        if (prior.exists && Array.isArray(prior.data()?.results)) {
          response.status(200).json({results: prior.data()?.results});
          return;
        }

        const results: SheetEditResult[] = [];
        for (const row of payload.rows) {
          results.push(await processRow(payload, mapping, row));
        }
        await eventRef.set({
          eventId: payload.eventId,
          results,
          processedAt: FieldValue.serverTimestamp(),
        });
        response.status(200).json({results});
      } catch (error) {
        logger.error("Sheet edit webhook failed", error);
        response.status(500).json({
          error: error instanceof Error ? error.message : String(error),
        });
      }
    },
  );
}
