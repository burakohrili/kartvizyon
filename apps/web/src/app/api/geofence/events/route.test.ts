import { beforeEach, describe, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({
  receivedRequest: undefined as Request | undefined,
}));

vi.mock("@/lib/supabase/server", () => ({
  createSupabaseServerClient: async (request?: Request) => {
    state.receivedRequest = request;
    return {
      auth: { getUser: async () => ({ data: { user: { id: "user-1" } } }) },
      from: () => ({
        insert: async () => ({ error: null }),
      }),
    };
  },
}));

const { POST } = await import("./route");

describe("saha modu olay kaydı", () => {
  beforeEach(() => {
    state.receivedRequest = undefined;
  });

  it("mobil Bearer oturumunu Supabase doğrulamasına iletir", async () => {
    const request = new Request(
      "https://app.kartvizyon.app/api/geofence/events",
      {
        method: "POST",
        headers: {
          authorization: "Bearer mobile-access-token",
          "content-type": "application/json",
        },
        body: JSON.stringify({
          workspaceId: "11111111-1111-4111-8111-111111111111",
          organizationId: null,
          companyId: "22222222-2222-4222-8222-222222222222",
          priorityScore: 80,
          distanceMeters: 120,
          outcome: "shown",
        }),
      },
    );
    const response = await POST(request);

    expect(response.status).toBe(204);
    expect(state.receivedRequest).toBe(request);
    expect(state.receivedRequest?.headers.get("authorization")).toBe(
      "Bearer mobile-access-token",
    );
  });
});
