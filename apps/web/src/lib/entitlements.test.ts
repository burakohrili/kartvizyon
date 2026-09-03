import { describe, expect, it } from "vitest";
import type { SupabaseClient } from "@supabase/supabase-js";
import { assertQuota, resolveEntitlement } from "./entitlements";

const PLANS: Record<string, Record<string, unknown>> = {
  free: {
    id: "free",
    name: "Ücretsiz",
    seat_limit: 1,
    monthly_ai_minutes: 10,
    monthly_document_bytes: 268435456,
    max_companies: 5,
    max_ocr: 5,
  },
  individual: {
    id: "individual",
    name: "Bireysel",
    seat_limit: 1,
    monthly_ai_minutes: 120,
    monthly_document_bytes: 5368709120,
    max_companies: null,
    max_ocr: 60,
  },
  team: {
    id: "team",
    name: "Ekip",
    seat_limit: 50,
    monthly_ai_minutes: 150,
    monthly_document_bytes: 21474836480,
    max_companies: null,
    max_ocr: 80,
  },
};

type FakeState = {
  subscription: Record<string, unknown> | null;
  workspaceCreatedAt: string;
  companies: number;
  memberships: number;
  ocrRecords: number;
  audioSeconds: number[];
  topUps: Record<string, number>[];
};

/**
 * Supabase istemcisinin yalnız `entitlements.ts` tarafından kullanılan zincir
 * yüzeyini taklit eder. Gerçek RLS davranışı ayrı entegrasyon testinin konusudur.
 */
function fakeSupabase(state: FakeState): SupabaseClient {
  const builder = (table: string) => {
    const chain: Record<string, unknown> = {};
    const self = () => chain;
    let metric: string | null = null;

    Object.assign(chain, {
      select: (_columns?: string, options?: { head?: boolean }) => {
        if (options?.head) {
          chain.__count = true;
        }
        return self();
      },
      eq: (column: string, value: unknown) => {
        if (column === "metric") metric = String(value);
        return self();
      },
      is: () => self(),
      gte: () => self(),
      order: () => self(),
      maybeSingle: async () => {
        if (table === "workspace_subscriptions") {
          return { data: state.subscription, error: null };
        }
        if (table === "workspaces") {
          return {
            data: { created_at: state.workspaceCreatedAt },
            error: null,
          };
        }
        if (table === "subscription_plans") {
          return { data: PLANS[String(chain.__planId ?? "free")], error: null };
        }
        return { data: null, error: null };
      },
      then: undefined,
    });

    // `await supabase.from(...)...` çağrıları için thenable davranışı.
    (chain as { then?: unknown }).then = (
      resolve: (value: unknown) => unknown,
    ) => {
      if (table === "companies") {
        return resolve({ count: state.companies, error: null });
      }
      if (table === "memberships") {
        return resolve({ count: state.memberships, error: null });
      }
      if (table === "workspace_ai_topups") {
        return resolve({ data: state.topUps, error: null });
      }
      if (table === "usage_records") {
        if (metric === "ocr") {
          return resolve({ count: state.ocrRecords, error: null });
        }
        return resolve({
          data: state.audioSeconds.map((quantity) => ({ quantity })),
          error: null,
        });
      }
      if (table === "ai_topup_packages") {
        return resolve({ data: [], error: null });
      }
      return resolve({ data: null, count: 0, error: null });
    };

    return chain;
  };

  return {
    from: (table: string) => {
      const chain = builder(table) as Record<string, unknown>;
      if (table === "subscription_plans") {
        const originalEq = chain.eq as (c: string, v: unknown) => unknown;
        chain.eq = (column: string, value: unknown) => {
          if (column === "id") chain.__planId = value;
          return originalEq(column, value);
        };
      }
      return chain;
    },
  } as unknown as SupabaseClient;
}

const NOW = new Date("2026-08-17T12:00:00.000Z");

function baseState(overrides: Partial<FakeState> = {}): FakeState {
  return {
    subscription: null,
    workspaceCreatedAt: "2026-08-15T00:00:00.000Z",
    companies: 0,
    memberships: 1,
    ocrRecords: 0,
    audioSeconds: [],
    topUps: [],
    ...overrides,
  };
}

const CONTEXT = (state: FakeState) => ({
  supabase: fakeSupabase(state),
  workspaceId: "workspace-1",
  organizationId: "org-1",
});

describe("resolveEntitlement", () => {
  it("abonelik satırı yokken çalışma alanı tarihinden 14 günlük deneme tanır", async () => {
    const state = baseState();
    const entitlement = await resolveEntitlement(
      fakeSupabase(state),
      "workspace-1",
      NOW,
    );
    expect(entitlement.trialActive).toBe(true);
    expect(entitlement.planId).toBe("individual");
    expect(entitlement.limits.companies).toBeNull();
  });

  it("deneme bittiğinde ücretsiz katmana düşer", async () => {
    const state = baseState({
      workspaceCreatedAt: "2026-06-01T00:00:00.000Z",
    });
    const entitlement = await resolveEntitlement(
      fakeSupabase(state),
      "workspace-1",
      NOW,
    );
    expect(entitlement.trialActive).toBe(false);
    expect(entitlement.planId).toBe("free");
    expect(entitlement.limits.companies).toBe(5);
  });

  it("ekip planında AI kotasını koltuk sayısıyla havuzlar", async () => {
    const state = baseState({
      subscription: {
        plan_id: "team",
        status: "active",
        seat_quantity: 4,
        trial_ends_at: null,
        current_period_start: "2026-08-01T00:00:00.000Z",
        current_period_end: "2026-09-01T00:00:00.000Z",
        plan: PLANS.team,
      },
    });
    const entitlement = await resolveEntitlement(
      fakeSupabase(state),
      "workspace-1",
      NOW,
    );
    expect(entitlement.limits.aiMinutes).toBe(600);
    expect(entitlement.limits.ocr).toBe(320);
  });

  it("iptal edilmiş abonelik dönem sonuna kadar plan limitini korur", async () => {
    const state = baseState({
      subscription: {
        plan_id: "individual",
        status: "cancelled",
        seat_quantity: 1,
        trial_ends_at: null,
        current_period_start: "2026-08-01T00:00:00.000Z",
        current_period_end: "2026-09-01T00:00:00.000Z",
        plan: PLANS.individual,
      },
    });
    const entitlement = await resolveEntitlement(
      fakeSupabase(state),
      "workspace-1",
      NOW,
    );
    expect(entitlement.planId).toBe("individual");
  });
});

describe("assertQuota", () => {
  it("ücretsiz katmanda 5. müşteri geçer, 6. reddedilir", async () => {
    const expired = { workspaceCreatedAt: "2026-06-01T00:00:00.000Z" };

    const under = baseState({ ...expired, companies: 4 });
    expect(await assertQuota(CONTEXT(under), "companies")).toBeNull();

    const atLimit = baseState({ ...expired, companies: 5 });
    const denied = await assertQuota(CONTEXT(atLimit), "companies");
    expect(denied?.status).toBe(402);
    const body = await denied!.json();
    expect(body.code).toBe("quota_exceeded");
    expect(body.quota).toBe("companies");
    expect(body.limit).toBe(5);
  });

  it("deneme aktifken müşteri limiti uygulanmaz", async () => {
    const state = baseState({ companies: 500 });
    const entitlement = await resolveEntitlement(
      fakeSupabase(state),
      "workspace-1",
      NOW,
    );
    expect(
      await assertQuota(CONTEXT(state), "companies", { entitlement }),
    ).toBeNull();
  });

  it("AI dakikası dolduğunda 402 döner", async () => {
    const state = baseState({
      workspaceCreatedAt: "2026-06-01T00:00:00.000Z",
      audioSeconds: [600],
    });
    const denied = await assertQuota(CONTEXT(state), "ai_minutes");
    expect(denied?.status).toBe(402);
    expect((await denied!.json()).quota).toBe("ai_minutes");
  });

  it("ek AI paketi kalan bakiyeyi kotaya ekler", async () => {
    const state = baseState({
      workspaceCreatedAt: "2026-06-01T00:00:00.000Z",
      audioSeconds: [600],
      topUps: [
        {
          ai_minutes_granted: 100,
          ai_minutes_used: 0,
          ocr_granted: 50,
          ocr_used: 0,
        },
      ],
    });
    expect(await assertQuota(CONTEXT(state), "ai_minutes")).toBeNull();
  });

  it("tüketilmiş ek paket kotayı artırmaz", async () => {
    const state = baseState({
      workspaceCreatedAt: "2026-06-01T00:00:00.000Z",
      audioSeconds: [600],
      topUps: [
        {
          ai_minutes_granted: 100,
          ai_minutes_used: 100,
          ocr_granted: 50,
          ocr_used: 50,
        },
      ],
    });
    expect((await assertQuota(CONTEXT(state), "ai_minutes"))?.status).toBe(402);
  });

  it("koltuk sayısı dolduğunda yeni üye reddedilir", async () => {
    const state = baseState({
      subscription: {
        plan_id: "team",
        status: "active",
        seat_quantity: 3,
        trial_ends_at: null,
        current_period_start: "2026-08-01T00:00:00.000Z",
        current_period_end: "2026-09-01T00:00:00.000Z",
        plan: PLANS.team,
      },
      memberships: 3,
    });
    const denied = await assertQuota(CONTEXT(state), "seats");
    expect(denied?.status).toBe(402);
    expect((await denied!.json()).quota).toBe("seats");
  });
});
