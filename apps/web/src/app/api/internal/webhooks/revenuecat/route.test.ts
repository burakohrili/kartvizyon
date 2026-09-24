import { createHmac } from "node:crypto";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { POST } from "./route";

const mocks = vi.hoisted(() => ({ admin: vi.fn(), rpc: vi.fn() }));
vi.mock("@/lib/supabase/admin", () => ({
  createSupabaseAdminClient: mocks.admin,
}));
const user = "11111111-1111-4111-8111-111111111111";
const workspace = "22222222-2222-4222-8222-222222222222";
const previousUser = "33333333-3333-4333-8333-333333333333";
const previousWorkspace = "44444444-4444-4444-8444-444444444444";
const baseEvent = {
  id: "test-purchase",
  type: "INITIAL_PURCHASE",
  event_timestamp_ms: 1800000000000,
  app_user_id: user,
  product_id: "app.kartvizyon.mobile.premium.monthly",
  store: "APP_STORE",
  environment: "PRODUCTION",
  transaction_id: "transaction-1",
  original_transaction_id: "original-1",
  purchased_at_ms: 1800000000000,
  expiration_at_ms: 1802592000000,
};
function request(body: string, auth = "Bearer test-only", age = 0) {
  const timestamp = Math.floor(Date.now() / 1000) - age;
  const signature = createHmac("sha256", "test-signing-key")
    .update(`${timestamp}.${body}`)
    .digest("hex");
  return new Request("https://example.test/api/internal/webhooks/revenuecat", {
    method: "POST",
    body,
    headers: {
      authorization: auth,
      "x-revenuecat-webhook-signature": `t=${timestamp},v1=${signature}`,
    },
  });
}
const payload = (event = {}) =>
  JSON.stringify({ api_version: "1.0", event: { ...baseEvent, ...event } });
function adminWithMapping(mapped = true) {
  const query = (data: unknown) => {
    const builder = {
      select: vi.fn(() => builder),
      eq: vi.fn(() => builder),
      in: vi.fn(() => builder),
      then: (resolve: (value: unknown) => unknown) =>
        Promise.resolve({ data, error: null }).then(resolve),
    };
    return builder;
  };
  mocks.admin.mockReturnValue({
    from: (table: string) =>
      query(
        table === "workspaces"
          ? [{ id: workspace, owner_user_id: user }]
          : mapped
            ? [{ plan_id: "individual", base_plan_id: null }]
            : [],
      ),
    rpc: mocks.rpc,
  });
}
beforeEach(() => {
  vi.resetAllMocks();
  vi.stubEnv("REVENUECAT_WEBHOOK_AUTHORIZATION", "Bearer test-only");
  vi.stubEnv("REVENUECAT_WEBHOOK_SIGNING_SECRET", "test-signing-key");
  vi.stubEnv("REVENUECAT_ALLOWED_ENVIRONMENT", "PRODUCTION");
  mocks.rpc.mockResolvedValue({ data: "processed", error: null });
});
afterEach(() => vi.unstubAllEnvs());

describe("RevenueCat HTTP boundary", () => {
  it("fails closed when signing configuration is missing", async () => {
    vi.stubEnv("REVENUECAT_WEBHOOK_SIGNING_SECRET", "");
    expect((await POST(request(payload()))).status).toBe(503);
    expect(mocks.admin).not.toHaveBeenCalled();
  });
  it("rejects wrong authorization before database access", async () => {
    expect((await POST(request(payload(), "wrong"))).status).toBe(401);
    expect(mocks.admin).not.toHaveBeenCalled();
  });
  it("rejects an old signed delivery", async () => {
    expect(
      (await POST(request(payload(), "Bearer test-only", 301))).status,
    ).toBe(401);
    expect(mocks.admin).not.toHaveBeenCalled();
  });
  it("rejects a tampered body", async () => {
    const signed = request(payload());
    const tampered = new Request(signed.url, {
      method: "POST",
      headers: signed.headers,
      body: payload({ id: "tampered" }),
    });
    expect((await POST(tampered)).status).toBe(401);
    expect(mocks.admin).not.toHaveBeenCalled();
  });
  it.each(["{", "{}"])("rejects malformed payload %s", async (body) => {
    expect((await POST(request(body))).status).toBe(400);
    expect(mocks.admin).not.toHaveBeenCalled();
  });
  it("acknowledges TEST without granting access", async () => {
    const response = await POST(
      request(
        payload({
          type: "TEST",
          transaction_id: null,
          original_transaction_id: null,
        }),
      ),
    );
    expect(await response.json()).toEqual({ received: true, test: true });
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("ignores a delivery from the wrong environment", async () => {
    const response = await POST(request(payload({ environment: "SANDBOX" })));
    expect(response.status).toBe(202);
    expect(await response.json()).toMatchObject({
      ignored: true,
      reason: "environment_mismatch",
    });
    expect(mocks.admin).not.toHaveBeenCalled();
  });
  it("accepts an anonymous app user when a UUID alias identifies the owner", async () => {
    adminWithMapping();
    const response = await POST(
      request(payload({ app_user_id: "$RCAnonymousID:abc", aliases: [user] })),
    );
    expect(response.status).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledWith(
      "apply_store_billing_event",
      expect.objectContaining({ user_id_input: user }),
    );
  });
  it.each(["SUBSCRIPTION_EXTENDED", "REFUND_REVERSED"])(
    "reconciles %s as active",
    async (type) => {
      adminWithMapping();
      expect((await POST(request(payload({ type })))).status).toBe(200);
      expect(mocks.rpc).toHaveBeenCalledWith(
        "apply_store_billing_event",
        expect.objectContaining({ status_input: "active" }),
      );
    },
  );
  it("uses grace-period expiry for a billing issue", async () => {
    adminWithMapping();
    const grace = baseEvent.expiration_at_ms + 86400000;
    expect(
      (
        await POST(
          request(
            payload({
              type: "BILLING_ISSUE",
              grace_period_expiration_at_ms: grace,
            }),
          ),
        )
      ).status,
    ).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledWith(
      "apply_store_billing_event",
      expect.objectContaining({
        expires_at_input: new Date(grace).toISOString(),
      }),
    );
  });
  it("atomically reconciles a transfer between personal workspaces", async () => {
    const query = (data: unknown) => {
      const builder = {
        select: vi.fn(() => builder),
        eq: vi.fn(() => builder),
        in: vi.fn(() => builder),
        then: (resolve: (value: unknown) => unknown) =>
          Promise.resolve({ data, error: null }).then(resolve),
      };
      return builder;
    };
    mocks.admin.mockReturnValue({
      from: vi.fn(() =>
        query([
          { id: previousWorkspace, owner_user_id: previousUser },
          { id: workspace, owner_user_id: user },
        ]),
      ),
      rpc: mocks.rpc,
    });
    const response = await POST(
      request(
        payload({
          type: "TRANSFER",
          app_user_id: undefined,
          product_id: undefined,
          transaction_id: undefined,
          original_transaction_id: undefined,
          transferred_from: [previousUser],
          transferred_to: [user],
        }),
      ),
    );
    expect(response.status).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledWith(
      "transfer_store_billing_ownership",
      expect.objectContaining({
        from_workspace_id_input: previousWorkspace,
        to_workspace_id_input: workspace,
      }),
    );
  });
  it("rejects missing subscription identity", async () => {
    expect(
      (await POST(request(payload({ transaction_id: undefined })))).status,
    ).toBe(400);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("rejects unmapped products without granting access", async () => {
    adminWithMapping(false);
    expect(
      (await POST(request(payload({ product_id: "unknown" })))).status,
    ).toBe(422);
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("passes verified purchase identity and dates to the atomic RPC", async () => {
    adminWithMapping();
    expect((await POST(request(payload()))).status).toBe(200);
    expect(mocks.rpc).toHaveBeenCalledWith(
      "apply_store_billing_event",
      expect.objectContaining({
        user_id_input: user,
        workspace_id_input: workspace,
        plan_id_input: "individual",
        environment_input: "PRODUCTION",
        status_input: "active",
        auto_renewing_input: true,
        expires_at_input: new Date(baseEvent.expiration_at_ms).toISOString(),
      }),
    );
  });
  it("acknowledges the RPC duplicate outcome", async () => {
    adminWithMapping();
    mocks.rpc.mockResolvedValue({ data: "duplicate", error: null });
    expect(await (await POST(request(payload()))).json()).toEqual({
      received: true,
      outcome: "duplicate",
    });
  });
});
