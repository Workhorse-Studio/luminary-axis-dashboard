export const CONTROL_HEADERS = [
  "_version",
  "_fieldHashes",
  "_delete",
  "_syncStatus",
] as const;

export const READ_ONLY_HEADERS = new Set([
  "docId",
  "parentId",
  "_version",
  "_fieldHashes",
  "_syncStatus",
]);

export interface ManagedSheetConfig {
  id: string;
  title: string;
  firestorePattern: string;
  parentId: boolean;
}

export interface SyncConfig {
  projectId: string;
  region: string;
  spreadsheetId: string;
  runtimeServiceAccount: string;
  sheetOwnerEmail: string;
  managedSheets: ManagedSheetConfig[];
}

export interface ManagedDocument {
  id: string;
  parentId?: string;
  data: Record<string, unknown>;
  version: string;
  deleted?: boolean;
}

export interface SheetEditRow {
  rowNumber: number;
  docId?: string;
  parentId?: string;
  version?: string;
  fieldHashes?: string;
  deleteRequested: boolean;
  changedHeaders: string[];
  values: Record<string, unknown>;
}

export interface SheetEditPayload {
  eventId: string;
  timestamp: number;
  spreadsheetId: string;
  sheetTitle: string;
  rows: SheetEditRow[];
}

export interface SheetEditResult {
  rowNumber: number;
  docId?: string;
  status: string;
  conflicts?: string[];
}
