import { describe, expect, it } from "vitest";

import { detectBusinessCardMimeType } from "./business-card";

describe("detectBusinessCardMimeType", () => {
  it("detects camera JPEG bytes even when multipart MIME is missing", () => {
    expect(
      detectBusinessCardMimeType(
        new Uint8Array([0xff, 0xd8, 0xff, 0xe1, 0x00, 0x18]),
      ),
    ).toBe("image/jpeg");
  });

  it("detects PNG and WebP signatures", () => {
    expect(
      detectBusinessCardMimeType(
        new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      ),
    ).toBe("image/png");
    expect(
      detectBusinessCardMimeType(
        new Uint8Array([
          0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50,
        ]),
      ),
    ).toBe("image/webp");
  });

  it("rejects unsupported or spoofed files", () => {
    expect(detectBusinessCardMimeType(new Uint8Array([1, 2, 3, 4]))).toBeNull();
  });
});
