import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const source = readFileSync(
  fileURLToPath(new URL("./route.ts", import.meta.url)),
  "utf8",
);

describe("reminder worker contract", () => {
  it("requires the existing cron secret and invokes the bounded database worker", () => {
    expect(source).toContain('hasInternalSecret(request, "CRON_SECRET")');
    expect(source).toContain('rpc("process_reminders"');
    expect(source).toContain("batch_limit: 500");
  });

  it("does not put notification content or personal data in structured logs", () => {
    expect(source).toContain('event: "reminders.processed"');
    expect(source).not.toContain("console.info(data)");
  });
});
