import { describe, expect, it } from "vitest";

import {
  detectBusinessCardMimeType,
  validateBusinessCardExtraction,
} from "./business-card";

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

describe("validateBusinessCardExtraction", () => {
  const baseOutput = {
    firstName: "Ayşe",
    lastName: "Yılmaz",
    title: null,
    companyName: "Örnek A.Ş.",
    phone: null,
    confidence: 0.9,
    needsReview: true as const,
  };

  it("normalizes a domain without a scheme", () => {
    expect(
      validateBusinessCardExtraction({
        ...baseOutput,
        email: "ayse@example.com",
        website: "example.com",
      }),
    ).toMatchObject({
      email: "ayse@example.com",
      website: "https://example.com",
      needsReview: true,
    });
  });

  it("keeps OCR review usable when contact formats are invalid", () => {
    expect(
      validateBusinessCardExtraction({
        ...baseOutput,
        email: "not-an-email",
        website: "not a website",
      }),
    ).toMatchObject({ email: null, website: null, needsReview: true });
  });
});
