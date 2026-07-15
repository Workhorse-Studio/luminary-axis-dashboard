import {createHash} from "node:crypto";

import {
  DocumentReference,
  GeoPoint,
  Timestamp,
} from "firebase-admin/firestore";

type PortableObject = Record<string, unknown>;

function canonicalize(value: unknown): unknown {
  if (value === undefined) return {$undefined: true};
  if (value === null || typeof value === "boolean" || typeof value === "string") {
    return value;
  }
  if (typeof value === "number") {
    if (Number.isNaN(value)) return {$number: "NaN"};
    if (value === Infinity) return {$number: "Infinity"};
    if (value === -Infinity) return {$number: "-Infinity"};
    return value;
  }
  if (value instanceof Timestamp) return {$timestamp: value.toDate().toISOString()};
  if (value instanceof Date) return {$date: value.toISOString()};
  if (value instanceof GeoPoint) {
    return {$geoPoint: {latitude: value.latitude, longitude: value.longitude}};
  }
  if (value instanceof DocumentReference) return {$reference: value.path};
  if (Buffer.isBuffer(value) || value instanceof Uint8Array) {
    return {$bytes: Buffer.from(value).toString("base64")};
  }
  if (Array.isArray(value)) return value.map(canonicalize);
  if (typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([key, entry]) => [key, canonicalize(entry)]),
    );
  }
  return String(value);
}

function restorePortable(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(restorePortable);
  if (!value || typeof value !== "object") return value;
  const object = value as PortableObject;
  if (typeof object.$timestamp === "string") {
    return Timestamp.fromDate(new Date(object.$timestamp));
  }
  if (typeof object.$date === "string") return new Date(object.$date);
  if (object.$geoPoint && typeof object.$geoPoint === "object") {
    const point = object.$geoPoint as Record<string, unknown>;
    return new GeoPoint(Number(point.latitude), Number(point.longitude));
  }
  if (typeof object.$bytes === "string") return Buffer.from(object.$bytes, "base64");
  return Object.fromEntries(
    Object.entries(object).map(([key, entry]) => [key, restorePortable(entry)]),
  );
}

export function stableJson(value: unknown): string {
  return JSON.stringify(canonicalize(value));
}

export function hashValue(value: unknown): string {
  return createHash("sha256").update(stableJson(value)).digest("base64url");
}

export function hashFields(data: Record<string, unknown>): Record<string, string> {
  return Object.fromEntries(
    Object.entries(data).map(([field, value]) => [field, hashValue(value)]),
  );
}

export function encodeCell(value: unknown): string | number | boolean {
  if (value === undefined || value === null) return "";
  if (typeof value === "string" || typeof value === "boolean") return value;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return stableJson(value);
}

export function decodeCell(raw: unknown, expected: unknown): unknown {
  if (raw === "" || raw === null || raw === undefined) {
    if (typeof expected === "string") return "";
    if (expected === undefined) return undefined;
    throw new Error("A non-string field cannot be cleared; enter a valid value instead");
  }

  if (typeof expected === "string") return String(raw);
  if (typeof expected === "number") {
    const value = typeof raw === "number" ? raw : Number(raw);
    if (!Number.isFinite(value)) throw new Error(`Expected a number, got ${String(raw)}`);
    return value;
  }
  if (typeof expected === "boolean") {
    if (typeof raw === "boolean") return raw;
    if (String(raw).toLowerCase() === "true") return true;
    if (String(raw).toLowerCase() === "false") return false;
    throw new Error(`Expected true or false, got ${String(raw)}`);
  }
  if (expected instanceof Timestamp) {
    const date = new Date(String(raw));
    if (Number.isNaN(date.valueOf())) throw new Error(`Invalid timestamp: ${String(raw)}`);
    return Timestamp.fromDate(date);
  }
  if (expected instanceof Date) {
    const date = new Date(String(raw));
    if (Number.isNaN(date.valueOf())) throw new Error(`Invalid date: ${String(raw)}`);
    return date;
  }
  if (Array.isArray(expected) || (expected && typeof expected === "object")) {
    if (typeof raw !== "string") throw new Error("Maps and arrays must be JSON text");
    return restorePortable(JSON.parse(raw));
  }

  if (typeof raw !== "string") return raw;
  const trimmed = raw.trim();
  if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
    return restorePortable(JSON.parse(trimmed));
  }
  return raw;
}

export function parseFieldHashes(raw: string | undefined): Record<string, string> {
  if (!raw) return {};
  try {
    const value = JSON.parse(raw) as unknown;
    if (!value || typeof value !== "object" || Array.isArray(value)) return {};
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .filter((entry): entry is [string, string] => typeof entry[1] === "string"),
    );
  } catch {
    return {};
  }
}
