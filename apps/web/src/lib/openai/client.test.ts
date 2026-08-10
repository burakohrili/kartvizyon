import { describe, expect, it } from "vitest";

import { normalizeOpenAiApiKey } from "./client";

describe("normalizeOpenAiApiKey", () => {
  it("removes BOM and surrounding whitespace from copied secrets", () => {
    expect(normalizeOpenAiApiKey("  \uFEFFsk-test-key\r\n")).toBe(
      "sk-test-key",
    );
  });

  it("rejects missing or empty secrets", () => {
    expect(() => normalizeOpenAiApiKey(undefined)).toThrow(
      "OPENAI_API_KEY_MISSING",
    );
    expect(() => normalizeOpenAiApiKey(" \uFEFF ")).toThrow(
      "OPENAI_API_KEY_MISSING",
    );
  });
});
