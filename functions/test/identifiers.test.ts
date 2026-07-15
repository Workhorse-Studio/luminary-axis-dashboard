import {describe, expect, it} from "vitest";

import {syncEventDocumentPath} from "../src/identifiers.js";

describe("sync identifiers", () => {
  it("creates a valid even-segment Firestore document path", () => {
    const path = syncEventDocumentPath("event-1");
    expect(path.split("/")).toHaveLength(2);
    expect(path).toMatch(/^__sheetSyncEvents\/[a-f0-9]{64}$/);
  });
});
