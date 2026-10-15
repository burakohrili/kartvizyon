import { describe, expect, it } from "vitest";
import { NextRequest } from "next/server";
import { POST } from "./route";

function request(body: unknown, origin = "https://kartvizyon.app") {
  return new NextRequest("https://kartvizyon.app/api/locale", {
    method: "POST",
    headers: { origin, "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("locale preference endpoint", () => {
  it("persists only supported languages in a same-site cookie", async () => {
    for (const locale of ["en", "tr"] as const) {
      const response = await POST(request({ locale }));
      expect(response.status).toBe(200);
      expect(response.cookies.get("kartvizyon_locale")?.value).toBe(locale);
      expect(response.cookies.get("kartvizyon_locale")?.httpOnly).toBe(true);
      expect(response.cookies.get("kartvizyon_locale")?.sameSite).toBe("lax");
    }
  });

  it("rejects cross-origin and unsupported locale changes", async () => {
    expect(
      (await POST(request({ locale: "en" }, "https://attacker.example")))
        .status,
    ).toBe(403);
    expect((await POST(request({ locale: "fr" }))).status).toBe(400);
  });
});
