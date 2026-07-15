import {describe, expect, it} from "vitest";

import {decodeCell, encodeCell, hashFields, hashValue} from "../src/codec.js";

describe("Firestore/Sheets value codec", () => {
  it("preserves string-looking numbers when the Firestore field is a string", () => {
    expect(decodeCell(123456, "01823456")).toBe("123456");
    expect(decodeCell("012345", "01823456")).toBe("012345");
  });

  it("round-trips maps and arrays through JSON cells", () => {
    const value = {students: ["a", "b"], attendance: {a: true}};
    const encoded = encodeCell(value);
    expect(typeof encoded).toBe("string");
    expect(decodeCell(encoded, value)).toEqual(value);
  });

  it("hashes object keys canonically", () => {
    expect(hashValue({a: 1, b: 2})).toBe(hashValue({b: 2, a: 1}));
    expect(hashFields({name: "Ada"})).toHaveProperty("name");
  });

  it("refuses to clear non-string values ambiguously", () => {
    expect(() => decodeCell("", 1)).toThrow(/cannot be cleared/);
    expect(() => decodeCell("", {a: 1})).toThrow(/cannot be cleared/);
  });
});
