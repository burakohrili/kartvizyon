import { describe, expect, it } from "vitest";
import { audioBucketName } from "./storage-config";

describe("audioBucketName", () => {
  it("uses the production bucket by default", () => {
    expect(audioBucketName(undefined)).toBe("visit-audio");
  });

  it("normalizes a quoted environment value", () => {
    expect(audioBucketName('  "visit-audio"  ')).toBe("visit-audio");
  });

  it.each(["", "https://example.com", "visit audio", "../visit-audio"])(
    "rejects an invalid bucket value: %s",
    (value) => {
      expect(audioBucketName(value)).toBe("visit-audio");
    },
  );
});
