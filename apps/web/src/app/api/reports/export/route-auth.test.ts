import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

describe("rapor dışa aktarma yetkilendirmesi", () => {
  it("kimliği doğrulanmamış isteğe dosya üretmez", () => {
    const source = readFileSync(
      join(__dirname, "[format]", "route.ts"),
      "utf8",
    );

    expect(source).toContain("if (!report.authenticated)");
    expect(source).toContain('{ error: "Oturum gerekli." }, { status: 401 }');
  });
});
