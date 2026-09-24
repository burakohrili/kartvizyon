import { describe, expect, it, vi } from "vitest";
import type { SupabaseClient } from "@supabase/supabase-js";
import {
  assertQuota,
  resolveEntitlement,
  type Entitlement,
} from "./entitlements";
const entitlement: Entitlement = {
  planId: "individual",
  planName: "Deneme",
  status: "trialing",
  readOnly: false,
  trialActive: true,
  trialEndsAt: "2026-10-01T00:00:00Z",
  accessEndsAt: "2026-10-01T00:00:00Z",
  seatsPurchased: 1,
  periodStart: new Date("2026-09-17T00:00:00Z"),
  limits: {
    companies: null,
    aiMinutes: 120,
    ocr: 60,
    aiSummaries: 60,
    documentBytes: 5368709120,
    seats: 1,
  },
  topUp: { aiMinutes: 0, ocr: 0 },
};
function client(data: unknown, error: unknown = null) {
  return {
    rpc: vi.fn().mockResolvedValue({ data, error }),
  } as unknown as SupabaseClient;
}
describe("server entitlement contract", () => {
  it("uses database time and converts its period into a Date", async () => {
    const db = client({
      ...entitlement,
      periodStart: entitlement.periodStart.toISOString(),
    });
    expect(await resolveEntitlement(db, "workspace")).toEqual(entitlement);
    expect(db.rpc).toHaveBeenCalledWith("workspace_entitlement", {
      workspace_id_input: "workspace",
    });
  });
  it("does not grant fallback rights on a database error", async () => {
    await expect(
      resolveEntitlement(client(null, new Error("unavailable")), "workspace"),
    ).rejects.toThrow("unavailable");
  });
  it("rejects malformed entitlement data", async () => {
    await expect(
      resolveEntitlement(client({ readOnly: false }), "workspace"),
    ).rejects.toThrow();
  });
  it("blocks manual creation when read only even with unlimited company allowance", async () => {
    const denied = await assertQuota(
      { supabase: client(null), workspaceId: "w", organizationId: null },
      "companies",
      { entitlement: { ...entitlement, readOnly: true } },
    );
    expect(denied?.status).toBe(402);
    expect((await denied?.json()).code).toBe("subscription_required");
  });
  it("meters manual text summaries independently", async () => {
    const denied = await assertQuota(
      {
        supabase: client({ ai_summary: 60, audio_seconds: 0, ocr: 0 }),
        workspaceId: "w",
        organizationId: null,
      },
      "ai_summaries",
      { entitlement },
    );
    expect(denied?.status).toBe(402);
  });
  it("checks the whole audio duration, preserving seconds", async () => {
    const ctx = {
      supabase: client({ ai_summary: 0, audio_seconds: 7100, ocr: 0 }),
      workspaceId: "w",
      organizationId: null,
    };
    expect(
      await assertQuota(ctx, "ai_minutes", { entitlement, amount: 100 / 60 }),
    ).toBeNull();
    expect(
      (await assertQuota(ctx, "ai_minutes", { entitlement, amount: 101 / 60 }))
        ?.status,
    ).toBe(402);
  });
  it("fails closed when usage cannot be read", async () => {
    await expect(
      assertQuota(
        {
          supabase: client(null, new Error("unavailable")),
          workspaceId: "w",
          organizationId: null,
        },
        "ocr",
        { entitlement },
      ),
    ).rejects.toThrow("unavailable");
  });
});
