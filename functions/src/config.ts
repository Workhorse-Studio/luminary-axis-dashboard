import fs from "node:fs";
import path from "node:path";

import {parse} from "yaml";

import type {ManagedSheetConfig, SyncConfig} from "./types.js";

function requiredString(value: unknown, key: string): string {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`Missing or invalid sync config value: ${key}`);
  }
  return value.trim();
}

export function loadSyncConfig(configPath?: string): SyncConfig {
  const resolvedPath = configPath ??
    process.env.SHEET_SYNC_CONFIG ??
    path.join(process.cwd(), "sync.config.yaml");
  const raw = parse(fs.readFileSync(resolvedPath, "utf8")) as Record<string, unknown>;
  if (!Array.isArray(raw.managedSheets) || raw.managedSheets.length === 0) {
    throw new Error("sync.config.yaml must define managedSheets");
  }

  const managedSheets: ManagedSheetConfig[] = raw.managedSheets.map((entry, index) => {
    if (!entry || typeof entry !== "object") {
      throw new Error(`managedSheets[${index}] must be an object`);
    }
    const item = entry as Record<string, unknown>;
    return {
      id: requiredString(item.id, `managedSheets[${index}].id`),
      title: requiredString(item.title, `managedSheets[${index}].title`),
      firestorePattern: requiredString(
        item.firestorePattern,
        `managedSheets[${index}].firestorePattern`,
      ),
      parentId: item.parentId === true,
    };
  });

  const ids = new Set(managedSheets.map((sheet) => sheet.id));
  const titles = new Set(managedSheets.map((sheet) => sheet.title));
  if (ids.size !== managedSheets.length || titles.size !== managedSheets.length) {
    throw new Error("Managed sheet IDs and titles must be unique");
  }

  return {
    projectId: requiredString(raw.projectId, "projectId"),
    region: requiredString(raw.region, "region"),
    spreadsheetId: requiredString(raw.spreadsheetId, "spreadsheetId"),
    runtimeServiceAccount: requiredString(
      raw.runtimeServiceAccount,
      "runtimeServiceAccount",
    ),
    sheetOwnerEmail: requiredString(raw.sheetOwnerEmail, "sheetOwnerEmail"),
    managedSheets,
  };
}

export function mappingById(config: SyncConfig, id: string): ManagedSheetConfig {
  const mapping = config.managedSheets.find((sheet) => sheet.id === id);
  if (!mapping) throw new Error(`Unknown sync mapping: ${id}`);
  return mapping;
}

export function mappingByTitle(
  config: SyncConfig,
  title: string,
): ManagedSheetConfig | undefined {
  return config.managedSheets.find((sheet) => sheet.title === title);
}
