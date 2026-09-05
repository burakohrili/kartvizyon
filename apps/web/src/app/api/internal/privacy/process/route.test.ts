import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const source = readFileSync(
  fileURLToPath(new URL("./route.ts", import.meta.url)),
  "utf8",
);

describe("privacy worker schema contract", () => {
  it("exports the visit audio metadata columns that exist in the database", () => {
    expect(source).toContain("mime_type,byte_size,created_at");
    expect(source).not.toContain("size_bytes");
    expect(source).not.toContain("duration_seconds");
  });

  it("does not delete an account that still owns an archived organization", () => {
    expect(source).toContain('.eq("owner_id", item.user_id)');
    expect(source).not.toContain('.is("archived_at", null)');
  });
});
