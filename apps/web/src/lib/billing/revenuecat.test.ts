import { createHmac } from "node:crypto";
import { describe, expect, it } from "vitest";
import {
  lifecycleFor,
  normalizeStore,
  revenueCatUserIds,
  splitStoreProduct,
  verifyRevenueCatSignature,
} from "./revenuecat";

describe("RevenueCat webhook güvenliği", () => {
  it("HMAC ve zaman penceresini doğrular", () => {
    const body = '{"event":{"id":"evt"}}';
    const signature = createHmac("sha256", "secret")
      .update(`1000.${body}`)
      .digest("hex");
    expect(
      verifyRevenueCatSignature(body, `t=1000,v1=${signature}`, "secret", 1001),
    ).toBe(true);
    expect(
      verifyRevenueCatSignature(body, `t=1000,v1=${signature}`, "secret", 1400),
    ).toBe(false);
  });

  it("mağaza ve Google base plan kimliğini normalize eder", () => {
    expect(normalizeStore("APP_STORE")).toBe("apple");
    expect(normalizeStore("PLAY_STORE")).toBe("google");
    expect(splitStoreProduct("premium_individual:annual", "google")).toEqual({
      productId: "premium_individual",
      basePlanId: "annual",
    });
  });

  it("iptalde dönem sonuna kadar cancelled durumu üretir", () => {
    expect(lifecycleFor({ type: "CANCELLATION" } as never)).toEqual({
      status: "cancelled",
      autoRenewing: false,
    });
  });
});

describe("revenueCatUserIds", () => {
  it("prefers the current id and keeps valid UUID aliases as fallbacks", () => {
    const current = "11111111-1111-4111-8111-111111111111";
    const original = "22222222-2222-4222-8222-222222222222";
    expect(
      revenueCatUserIds({
        id: "event",
        type: "RENEWAL",
        event_timestamp_ms: 1,
        app_user_id: current,
        original_app_user_id: original,
        aliases: ["$RCAnonymousID:ignored", original],
      }),
    ).toEqual([current, original]);
  });
});
