import { beforeEach, describe, expect, it, vi } from "vitest";

const workspaceId = "00000000-0000-4000-8000-000000000001";
const companyId = "00000000-0000-4000-8000-000000000002";
let written: Record<string, unknown> | null = null;

function query(table: string) {
  const builder: Record<string, unknown> = {};
  for (const method of ["select", "eq", "is"]) {
    builder[method] = () => builder;
  }
  builder.maybeSingle = async () =>
    table === "companies" ? { data: { id: companyId }, error: null } : null;
  builder.insert = (value: Record<string, unknown>) => {
    written = value;
    return builder;
  };
  builder.single = async () => ({
    data: { id: "00000000-0000-4000-8000-000000000003", ...written },
    error: null,
  });
  return builder;
}

vi.mock("@/lib/api-context", () => ({
  getApiContext: async () => ({
    ok: true,
    workspaceId,
    organizationId: null,
    user: { id: "00000000-0000-4000-8000-000000000004" },
    supabase: { from: (table: string) => query(table) },
  }),
}));

const { POST } = await import("./route");

beforeEach(() => {
  written = null;
});

describe("visits API", () => {
  it("omits optional planning_note when ordinary visit flow has no note", async () => {
    const response = await POST(
      new Request("https://app.kartvizyon.app/api/visits", {
        method: "POST",
        body: JSON.stringify({
          workspaceId,
          organizationId: null,
          companyId,
          startedAt: "2026-10-15T19:10:00.000Z",
          clientMutationId: "00000000-0000-4000-8000-000000000005",
        }),
      }),
    );

    expect(response.status).toBe(201);
    expect(written).not.toHaveProperty("planning_note");
    expect(written).not.toHaveProperty("visit_type");
  });

  it("persists planning_note when the user supplies one", async () => {
    const response = await POST(
      new Request("https://app.kartvizyon.app/api/visits", {
        method: "POST",
        body: JSON.stringify({
          workspaceId,
          organizationId: null,
          companyId,
          planningNote: "Satın alma müdürü de katılacak.",
          clientMutationId: "00000000-0000-4000-8000-000000000006",
        }),
      }),
    );

    expect(response.status).toBe(201);
    expect(written).toHaveProperty(
      "planning_note",
      "Satın alma müdürü de katılacak.",
    );
  });
});
