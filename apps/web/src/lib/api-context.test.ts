import { beforeEach, describe, expect, it, vi } from "vitest";

/**
 * Çalışma alanı çözümlemesi.
 *
 * Mobil istemci çerez göndermiyor ve uçların çoğuna `workspaceId` de
 * eklemiyordu; bu yüzden "RLS'in gösterdiği ilk çalışma alanı" geri düşüşü
 * devreye giriyor ve birden fazla çalışma alanı olan kullanıcı yanlış alanın
 * verisini okuyordu.
 */

const cookieValue = { current: "cookie-workspace" };
const visibleWorkspaces = new Set<string>();

vi.mock("next/headers", () => ({
  cookies: async () => ({
    get: (name: string) =>
      name === "kartvizyon_workspace"
        ? { value: cookieValue.current }
        : undefined,
  }),
}));

function workspaceQuery() {
  let requested: string | null = null;
  const builder = {
    select: () => builder,
    eq: (_column: string, value: string) => {
      requested = value;
      return builder;
    },
    limit: () => builder,
    single: async () =>
      requested === null
        ? { data: { id: "first-workspace", organization_id: null } }
        : visibleWorkspaces.has(requested)
          ? { data: { id: requested, organization_id: null } }
          : { data: null },
  };
  return builder;
}

vi.mock("@/lib/supabase/server", () => ({
  createSupabaseServerClient: async () => ({
    auth: { getUser: async () => ({ data: { user: { id: "user-1" } } }) },
    rpc: async () => ({ data: true, error: null }),
    from: () => workspaceQuery(),
  }),
}));

const { getApiContext } = await import("./api-context");

function request(url: string, headers: Record<string, string> = {}) {
  return new Request(url, { headers });
}

beforeEach(() => {
  cookieValue.current = "cookie-workspace";
  visibleWorkspaces.clear();
  visibleWorkspaces.add("cookie-workspace");
  visibleWorkspaces.add("header-workspace");
});

describe("çalışma alanı çözümlemesi", () => {
  it("başlık çerezi ezer", async () => {
    const context = await getApiContext(
      request("https://app.kartvizyon.app/api/opportunities", {
        "x-kartvizyon-workspace": "header-workspace",
      }),
    );

    expect(context.ok).toBe(true);
    if (context.ok) expect(context.workspaceId).toBe("header-workspace");
  });

  it("başlık yoksa sorgu parametresi kullanılır", async () => {
    visibleWorkspaces.add("query-workspace");
    const context = await getApiContext(
      request(
        "https://app.kartvizyon.app/api/tasks?workspaceId=query-workspace",
      ),
    );

    expect(context.ok).toBe(true);
    if (context.ok) expect(context.workspaceId).toBe("query-workspace");
  });

  it("başlık ve parametre yoksa çerez kullanılır", async () => {
    const context = await getApiContext(
      request("https://app.kartvizyon.app/api/tasks"),
    );

    expect(context.ok).toBe(true);
    if (context.ok) expect(context.workspaceId).toBe("cookie-workspace");
  });

  it("erişilemeyen çalışma alanı 403 döner", async () => {
    const context = await getApiContext(
      request("https://app.kartvizyon.app/api/tasks", {
        "x-kartvizyon-workspace": "baska-firmanin-alani",
      }),
    );

    expect(context.ok).toBe(false);
    if (!context.ok) expect(context.response.status).toBe(403);
  });
});
