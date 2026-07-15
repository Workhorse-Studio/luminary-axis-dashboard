import {describe, expect, it} from "vitest";

import {
  buildHeaders,
  buildRow,
  columnName,
  findUpsertRow,
  recordKey,
} from "../src/rows.js";

describe("managed sheet rows", () => {
  it("builds deterministic schema-derived headers", () => {
    const documents = [
      {id: "a", data: {name: "Ada", role: "student"}, version: "v1"},
      {id: "b", data: {email: "b@example.com", name: "Bob"}, version: "v2"},
    ];
    expect(buildHeaders(documents, false)).toEqual([
      "docId",
      "email",
      "name",
      "role",
      "_version",
      "_fieldHashes",
      "_delete",
      "_syncStatus",
    ]);
  });

  it("exports tombstones and parent IDs", () => {
    const headers = buildHeaders([], true);
    const row = buildRow(headers, {
      id: "archive-1",
      parentId: "class-a",
      data: {},
      version: "v1",
      deleted: true,
    });
    expect(row[headers.indexOf("parentId")]).toBe("class-a");
    expect(row[headers.indexOf("_delete")]).toBe(true);
    expect(row[headers.indexOf("_syncStatus")]).toBe("DELETED");
  });

  it("uses stable record keys and A1 column names", () => {
    expect(recordKey("doc", "parent")).toBe("parent::doc");
    expect(columnName(0)).toBe("A");
    expect(columnName(25)).toBe("Z");
    expect(columnName(26)).toBe("AA");
  });

  it("appends after the last docId even when checkbox rows look populated", () => {
    const rows: unknown[][] = [
      ["docId", "name", "_delete"],
      ["a", "Ada", false],
      ["b", "Bob", false],
      ...Array.from({length: 997}, () => ["", "", false]),
    ];
    expect(findUpsertRow(rows[0] as string[], rows, "new-doc")).toBe(4);
    expect(findUpsertRow(rows[0] as string[], rows, "b")).toBe(3);
  });
});
