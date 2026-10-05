import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  reconcileSandboxCustomer,
  sandboxReadDiagnostic,
  sandboxReconciliationEnabled,
  sandboxTestUser,
} from "./sandbox-reconciliation";

const mocks = vi.hoisted(() => ({
  admin: vi.fn(),
  rpc: vi.fn(),
  fetch: vi.fn(),
}));
vi.mock("@/lib/supabase/admin", () => ({
  createSupabaseAdminClient: mocks.admin,
}));
const workspaceId = "3d0567bc-a4ee-40cb-87f2-64dbf0037939";
const subscription = {
  id: "sub-test",
  customer_id: sandboxTestUser,
  original_customer_id: "db2f81d6-70a1-44c5-a1e4-17a91c039ddf",
  product_id: "prodab878592e8",
  environment: "sandbox",
  store: "app_store",
  store_subscription_identifier: "latest-transaction",
  gives_access: true,
  current_period_starts_at: Date.now() - 60000,
  current_period_ends_at: Date.now() + 3600000,
  auto_renewal_status: "will_renew",
  status: "active",
  entitlements: { items: [{ id: "entl61d06d06c8" }] },
};
const purchase = {
  app_id: "appdde822f723",
  environment: "SANDBOX",
  store: "APP_STORE",
  product_id: "app.kartvizyon.mobile.premium.monthly",
  transaction_id: "latest-transaction",
  original_transaction_id: "root-transaction",
};
function list(items: unknown[]) {
  return Response.json({ items, next_page: null });
}
function admin(owner = sandboxTestUser, existing: unknown = null) {
  mocks.admin.mockReturnValue({
    from: (table: string) => {
      const result =
        table === "workspaces"
          ? { id: workspaceId, owner_user_id: owner }
          : table === "billing_product_mappings"
            ? { plan_id: "individual" }
            : existing;
      const builder = {
        select: () => builder,
        eq: () => builder,
        is: () => builder,
        maybeSingle: async () => ({ data: result, error: null }),
      };
      return builder;
    },
    rpc: mocks.rpc,
  });
}
function snapshots(value = subscription, event: unknown = purchase) {
  mocks.fetch.mockImplementation(async (url: string) =>
    url.includes("/subscriptions?") ? list([value]) : list([{ body: event }]),
  );
}
beforeEach(() => {
  vi.resetAllMocks();
  vi.stubEnv("REVENUECAT_ALLOWED_ENVIRONMENT", "SANDBOX");
  vi.stubEnv(
    "NEXT_PUBLIC_SUPABASE_URL",
    "https://rfzmdpxnfsvatukkedrg.supabase.co",
  );
  vi.stubEnv("REVENUECAT_SANDBOX_READ_API_KEY", "read-token");
  vi.stubGlobal("fetch", mocks.fetch);
  mocks.rpc.mockResolvedValue({ data: "processed", error: null });
  admin();
  snapshots();
});
afterEach(() => {
  vi.unstubAllEnvs();
  vi.unstubAllGlobals();
});

describe("Scoped Sandbox ownership reconciliation", () => {
  it.each([
    ["REVENUECAT_ALLOWED_ENVIRONMENT", "PRODUCTION"],
    ["NEXT_PUBLIC_SUPABASE_URL", "https://nweqbfxihinuflnfolne.supabase.co"],
    ["REVENUECAT_SANDBOX_READ_API_KEY", ""],
  ])("never runs with unsafe %s", async (name, value) => {
    vi.stubEnv(name, value);
    expect(sandboxReconciliationEnabled()).toBe(false);
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe("disabled");
    expect(mocks.fetch).not.toHaveBeenCalled();
    expect(mocks.admin).not.toHaveBeenCalled();
  });
  it("does not expose the privileged read to another user", async () => {
    expect(await reconcileSandboxCustomer("other-user")).toBe("disabled");
    expect(mocks.fetch).not.toHaveBeenCalled();
  });
  it("requires the authenticated user's personal workspace", async () => {
    expect(
      await reconcileSandboxCustomer(sandboxTestUser, "other-workspace"),
    ).toBe("owner_mismatch");
    expect(mocks.fetch).not.toHaveBeenCalled();
  });
  it("independently verifies the database owner", async () => {
    admin("other-owner");
    expect(await reconcileSandboxCustomer(sandboxTestUser, workspaceId)).toBe(
      "owner_mismatch",
    );
    expect(mocks.fetch).not.toHaveBeenCalled();
  });
  it("uses a verified root transaction and an explicitly audited snapshot", async () => {
    expect(await reconcileSandboxCustomer(sandboxTestUser, workspaceId)).toBe(
      "processed",
    );
    expect(mocks.rpc).toHaveBeenCalledWith(
      "apply_store_billing_event",
      expect.objectContaining({
        user_id_input: sandboxTestUser,
        workspace_id_input: workspaceId,
        environment_input: "SANDBOX",
        original_transaction_id_input: "root-transaction",
        transaction_id_input: "latest-transaction",
        status_input: "active",
        event_type_input: "SANDBOX_SERVER_SNAPSHOT",
      }),
    );
    expect(mocks.fetch).toHaveBeenCalledWith(
      expect.stringMatching(
        /^https:\/\/api.revenuecat.com\/v2\/projects\/proje9671fdf\//,
      ),
      expect.objectContaining({ cache: "no-store", redirect: "error" }),
    );
  });
  it.each([
    { customer_id: "other-owner" },
    { original_customer_id: "unexpected-source" },
    { environment: "production" },
    { store: "promotional" },
    { product_id: "wrong-product" },
    { entitlements: { items: [] } },
  ])("refuses unverified subscription %j", async (change) => {
    snapshots({ ...subscription, ...change } as typeof subscription);
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe(
      "no_verified_subscription",
    );
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("refuses to invent a root transaction from the latest transaction", async () => {
    snapshots(subscription, {
      ...purchase,
      original_transaction_id: undefined,
    });
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe(
      "missing_original_transaction",
    );
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("verifies the real v2 envelope app_id instead of inventing it", async () => {
    const { app_id, ...body } = purchase;
    mocks.fetch.mockImplementation(async (url: string) =>
      url.includes("/subscriptions?")
        ? list([subscription])
        : list([{ app_id, body }]),
    );
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe("processed");
    expect(mocks.rpc).toHaveBeenCalledTimes(1);
  });
  it("rejects an event from a different app envelope", async () => {
    const { app_id: _appId, ...body } = purchase;
    void _appId;
    mocks.fetch.mockImplementation(async (url: string) =>
      url.includes("/subscriptions?")
        ? list([subscription])
        : list([{ app_id: "other-app", body }]),
    );
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe(
      "missing_original_transaction",
    );
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("rejects production transaction proof", async () => {
    snapshots(subscription, { ...purchase, environment: "PRODUCTION" });
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe(
      "missing_original_transaction",
    );
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("rejects ownership changing during verification", async () => {
    let reads = 0;
    mocks.fetch.mockImplementation(async (url: string) =>
      url.includes("/subscriptions?")
        ? list(++reads === 1 ? [subscription] : [])
        : list([{ body: { event: purchase } }]),
    );
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe(
      "snapshot_changed",
    );
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("never follows an external pagination URL with the secret", async () => {
    mocks.fetch.mockImplementation(async (url: string) =>
      url.includes("/subscriptions?")
        ? list([subscription])
        : Response.json({
            items: [],
            next_page: "https://evil.invalid/capture",
          }),
    );
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe("unavailable");
    expect(mocks.fetch).toHaveBeenCalledTimes(2);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("does not grant on an API error", async () => {
    mocks.fetch.mockResolvedValue(new Response("no", { status: 403 }));
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe("unavailable");
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("keeps access until period end after cancellation", async () => {
    snapshots({ ...subscription, auto_renewal_status: "will_not_renew" });
    await reconcileSandboxCustomer(sandboxTestUser);
    expect(mocks.rpc).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({
        status_input: "cancelled",
        auto_renewing_input: false,
        expires_at_input: new Date(
          subscription.current_period_ends_at,
        ).toISOString(),
      }),
    );
  });
  it("does not keep access when RevenueCat says gives_access=false", async () => {
    snapshots({ ...subscription, gives_access: false });
    await reconcileSandboxCustomer(sandboxTestUser);
    const args = mocks.rpc.mock.calls[0][1];
    expect(args.status_input).toBe("expired");
    expect(Date.parse(args.expires_at_input)).toBeLessThanOrEqual(Date.now());
  });
  it("avoids repeated audit writes for unchanged subscription state", async () => {
    admin(sandboxTestUser, {
      user_id: sandboxTestUser,
      workspace_id: workspaceId,
      transaction_id: purchase.transaction_id,
      status: "active",
      auto_renewing: true,
      expires_at: new Date(subscription.current_period_ends_at).toISOString(),
    });
    expect(await reconcileSandboxCustomer(sandboxTestUser)).toBe("unchanged");
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("signed TEST diagnostics only read; never grant", async () => {
    expect(await sandboxReadDiagnostic()).toMatchObject({
      connected: true,
      targetSubscriptions: 1,
    });
    expect(mocks.admin).not.toHaveBeenCalled();
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
});
