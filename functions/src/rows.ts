import {encodeCell, hashFields} from "./codec.js";
import {CONTROL_HEADERS, type ManagedDocument} from "./types.js";

export function buildHeaders(
  documents: ManagedDocument[],
  hasParentId: boolean,
): string[] {
  const fields = new Set<string>();
  for (const document of documents) {
    for (const field of Object.keys(document.data)) fields.add(field);
  }
  return [
    "docId",
    ...(hasParentId ? ["parentId"] : []),
    ...[...fields].sort((left, right) => left.localeCompare(right)),
    ...CONTROL_HEADERS,
  ];
}

export function buildRow(
  headers: string[],
  document: ManagedDocument,
): Array<string | number | boolean> {
  const hashes = hashFields(document.data);
  return headers.map((header) => {
    switch (header) {
      case "docId": return document.id;
      case "parentId": return document.parentId ?? "";
      case "_version": return document.version;
      case "_fieldHashes": return JSON.stringify(hashes);
      case "_delete": return document.deleted === true;
      case "_syncStatus": return document.deleted ? "DELETED" : "OK";
      default: return encodeCell(document.data[header]);
    }
  });
}

export function recordKey(docId: string, parentId?: string): string {
  return `${parentId ?? ""}::${docId}`;
}

export function columnName(index: number): string {
  let value = index + 1;
  let result = "";
  while (value > 0) {
    value -= 1;
    result = String.fromCharCode(65 + (value % 26)) + result;
    value = Math.floor(value / 26);
  }
  return result;
}

export function quoteSheetTitle(title: string): string {
  return `'${title.replaceAll("'", "''")}'`;
}

export function findUpsertRow(
  headers: string[],
  rows: unknown[][],
  docId: string,
  parentId?: string,
): number {
  const docIdColumn = headers.indexOf("docId");
  const parentIdColumn = headers.indexOf("parentId");
  const targetKey = recordKey(docId, parentId);
  let lastKeyedRowIndex = 0;
  for (let index = 1; index < rows.length; index += 1) {
    const existingId = String(rows[index][docIdColumn] ?? "").trim();
    if (!existingId) continue;
    lastKeyedRowIndex = index;
    const existingParent = parentIdColumn >= 0
      ? String(rows[index][parentIdColumn] ?? "")
      : undefined;
    if (recordKey(existingId, existingParent) === targetKey) return index + 1;
  }
  return lastKeyedRowIndex + 2;
}
