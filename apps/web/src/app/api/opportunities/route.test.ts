import { beforeEach, describe, expect, it, vi } from "vitest";

const workspaceId = "00000000-0000-4000-8000-000000000001";
const companyId = "00000000-0000-4000-8000-000000000002";
const userId = "00000000-0000-4000-8000-000000000003";
const opportunityId = "00000000-0000-4000-8000-000000000004";
let companyValid = true;
let ownerValid = true;
let denied: Response | null = null;
let written: Record<string, unknown> | null = null;

function query(table: string) {
  const builder: Record<string, unknown> = {};
  for (const method of ["select", "eq", "is", "order"]) {
    builder[method] = () => builder;
  }
  builder.insert = (value: Record<string, unknown>) => {
    written = value;
    return builder;
  };
  builder.update = (value: Record<string, unknown>) => {
    written = value;
    return builder;
  };
  builder.maybeSingle = async () => ({
    data:
      table === "companies"
        ? companyValid
          ? { id: companyId }
          : null
        : ownerValid
          ? { id: "membership" }
          : null,
    error: null,
  });
  builder.single = async () => ({
    data: { id: opportunityId, ...written },
    error: null,
  });
  return builder;
}

vi.mock("@/lib/api-context", () => ({
  getApiContext: async () =>
    denied
      ? { ok: false, response: denied }
      : {
          ok: true,
          workspaceId,
          organizationId: "00000000-0000-4000-8000-000000000005",
          user: { id: userId, email: "user@example.com" },
          supabase: { from: (table: string) => query(table) },
        },
}));

const { PATCH, POST } = await import("./route");

function createBody(overrides: Record<string, unknown> = {}) {
  return {
    workspaceId,
    companyId,
    title: "Yeni soğutma sistemi",
    stage: "proposal",
    estimatedValue: 250000,
    currency: "TRY",
    probability: 60,
    expectedCloseDate: "2026-10-15",
    competitor: "Rakip A",
    assignedTo: userId,
    ...overrides,
  };
}

beforeEach(() => {
  companyValid = true;
  ownerValid = true;
  denied = null;
  written = null;
});

describe("opportunities API", () => {
  it.each(["TRY", "USD", "EUR"])(
    "%s fırsatı tüm create alanlarıyla oluşturur",
    async (currency) => {
      const response = await POST(
        new Request("https://app.kartvizyon.app/api/opportunities", {
          method: "POST",
          body: JSON.stringify(createBody({ currency })),
        }),
      );
      expect(response.status).toBe(201);
      expect(written).toMatchObject({
        currency,
        probability: 60,
        expected_close_date: "2026-10-15",
        competitor: "Rakip A",
        assigned_to: userId,
      });
    },
  );

  it("değer, currency, probability ve aşamayı günceller", async () => {
    const response = await PATCH(
      new Request("https://app.kartvizyon.app/api/opportunities", {
        method: "PATCH",
        body: JSON.stringify({
          ...createBody({ workspaceId: undefined, companyId: undefined }),
          id: opportunityId,
          stage: "won",
          probability: 100,
          currency: "EUR",
          estimatedValue: 99000,
        }),
      }),
    );
    expect(response.status).toBe(200);
    expect(written).toMatchObject({
      stage: "won",
      probability: 100,
      currency: "EUR",
      estimated_value: 99000,
    });
  });

  it("cross-tenant customer ve geçersiz owner'ı reddeder", async () => {
    companyValid = false;
    expect(
      (
        await POST(
          new Request("https://app.kartvizyon.app/api/opportunities", {
            method: "POST",
            body: JSON.stringify(createBody()),
          }),
        )
      ).status,
    ).toBe(400);
    companyValid = true;
    ownerValid = false;
    expect(
      (
        await POST(
          new Request("https://app.kartvizyon.app/api/opportunities", {
            method: "POST",
            body: JSON.stringify(
              createBody({
                assignedTo: "00000000-0000-4000-8000-000000000099",
              }),
            ),
          }),
        )
      ).status,
    ).toBe(400);
  });

  it("read-only context create ve update'i durdurur", async () => {
    denied = Response.json({ error: "Abonelik gerekli." }, { status: 402 });
    const create = await POST(
      new Request("https://app.kartvizyon.app/api/opportunities", {
        method: "POST",
        body: JSON.stringify(createBody()),
      }),
    );
    const update = await PATCH(
      new Request("https://app.kartvizyon.app/api/opportunities", {
        method: "PATCH",
        body: JSON.stringify({
          ...createBody({ workspaceId: undefined, companyId: undefined }),
          id: opportunityId,
        }),
      }),
    );
    expect(create.status).toBe(402);
    expect(update.status).toBe(402);
    expect(written).toBeNull();
  });
});
