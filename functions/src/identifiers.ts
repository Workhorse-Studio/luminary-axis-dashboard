import {createHash} from "node:crypto";

export function syncEventDocumentPath(eventId: string): string {
  const eventKey = createHash("sha256").update(eventId).digest("hex");
  return `__sheetSyncEvents/${eventKey}`;
}
