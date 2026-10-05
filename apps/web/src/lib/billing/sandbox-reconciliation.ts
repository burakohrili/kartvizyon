import { createHash } from "node:crypto";
import { z } from "zod";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

// Temporary, narrowly scoped recovery for the approved cross-environment test.
// Never use an email, caller-supplied receipt, or SDK entitlement as authority.
export const sandboxTestUser = "d9b9a47f-b4bf-4bc6-8a91-5596df284b0c";
const originalTestUser = "db2f81d6-70a1-44c5-a1e4-17a91c039ddf";
const project = "proje9671fdf";
const product = "app.kartvizyon.mobile.premium.monthly";
const customerPath = (id: string) =>
  `/v2/projects/${project}/customers/${encodeURIComponent(id)}`;
const subscriptionSchema = z.object({
  id: z.string().min(1),
  customer_id: z.string(),
  original_customer_id: z.string(),
  product_id: z.literal("prodab878592e8"),
  environment: z.literal("sandbox"),
  store: z.literal("app_store"),
  store_subscription_identifier: z.string().min(1),
  gives_access: z.boolean(),
  current_period_starts_at: z.number().int().positive(),
  current_period_ends_at: z.number().int().positive(),
  auto_renewal_status: z.string(),
  status: z.string(),
  entitlements: z.object({
    items: z.array(z.object({ id: z.string() })),
  }),
});
type Subscription = z.infer<typeof subscriptionSchema>;
const listSchema = z.object({
  items: z.array(z.unknown()),
  next_page: z.string().nullable().optional(),
});
const purchaseSchema = z.object({
  app_id: z.literal("appdde822f723"),
  environment: z.literal("SANDBOX"),
  store: z.literal("APP_STORE"),
  product_id: z.literal(product),
  transaction_id: z.string().min(1),
  original_transaction_id: z.string().min(1),
});

export function sandboxReconciliationEnabled(userId = sandboxTestUser) {
  return (
    userId === sandboxTestUser &&
    process.env.REVENUECAT_ALLOWED_ENVIRONMENT === "SANDBOX" &&
    process.env.NEXT_PUBLIC_SUPABASE_URL ===
      "https://rfzmdpxnfsvatukkedrg.supabase.co" &&
    Boolean(process.env.REVENUECAT_SANDBOX_READ_API_KEY)
  );
}

async function readList(path: string) {
  // Hard-coded origin; do not follow API pagination/redirects with the secret.
  const response = await fetch(`https://api.revenuecat.com${path}`, {
    headers: {
      Authorization: `Bearer ${process.env.REVENUECAT_SANDBOX_READ_API_KEY}`,
    },
    cache: "no-store",
    redirect: "error",
    signal: AbortSignal.timeout(5000),
  });
  if (!response.ok)
    throw new Error(`Sandbox RC read failed (${response.status})`);
  return listSchema.parse(await response.json());
}

async function readSubscriptions() {
  const list = await readList(
    `${customerPath(sandboxTestUser)}/subscriptions?environment=sandbox&limit=100`,
  );
  // Refuse incomplete snapshots rather than granting from an arbitrary page.
  if (list.next_page)
    throw new Error("Sandbox subscription pagination unsupported");
  return list.items.flatMap((item) => {
    const parsed = subscriptionSchema.safeParse(item);
    return parsed.success &&
      parsed.data.customer_id === sandboxTestUser &&
      [sandboxTestUser, originalTestUser].includes(
        parsed.data.original_customer_id,
      ) &&
      parsed.data.entitlements.items.some(
        (entry) => entry.id === "entl61d06d06c8",
      )
      ? [parsed.data]
      : [];
  });
}

async function findPurchase(subscription: Subscription) {
  for (const customer of new Set([
    sandboxTestUser,
    subscription.original_customer_id,
  ])) {
    const path = `${customerPath(customer)}/events`;
    let cursor: string | undefined;
    // Bounded history, reconstructing only an encoded cursor on the fixed path.
    for (let page = 0; page < 3; page++) {
      const events = await readList(
        `${path}?environment=sandbox&limit=100${cursor ? `&starting_after=${encodeURIComponent(cursor)}` : ""}`,
      );
      for (const item of events.items) {
        if (!item || typeof item !== "object" || !("body" in item)) continue;
        const body = item.body;
        const event =
          body && typeof body === "object" && "event" in body
            ? body.event
            : body;
        // V2 customer events carry app_id in the envelope, not in body.
        const proof =
          event && typeof event === "object"
            ? {
                ...event,
                app_id:
                  "app_id" in event
                    ? event.app_id
                    : "app_id" in item
                      ? item.app_id
                      : undefined,
              }
            : event;
        const parsed = purchaseSchema.safeParse(proof);
        if (
          parsed.success &&
          parsed.data.transaction_id ===
            subscription.store_subscription_identifier
        )
          return parsed.data;
      }
      if (!events.next_page) break;
      const next = new URL(events.next_page, "https://api.revenuecat.com");
      if (
        next.origin !== "https://api.revenuecat.com" ||
        next.pathname !== path
      )
        throw new Error("Unexpected Sandbox event pagination");
      cursor = next.searchParams.get("starting_after") ?? undefined;
      if (!cursor) throw new Error("Missing Sandbox event cursor");
    }
  }
  return null;
}

export async function sandboxReadDiagnostic() {
  if (!sandboxReconciliationEnabled()) return undefined;
  try {
    const subscriptions = await readSubscriptions();
    const source = await readList(
      `${customerPath(originalTestUser)}/events?environment=sandbox&limit=1`,
    );
    const sourceSubscriptions = await readList(
      `${customerPath(originalTestUser)}/subscriptions?environment=sandbox&limit=100`,
    );
    const sourceSubscription = sourceSubscriptions.items[0];
    const recognized = subscriptionSchema.safeParse(sourceSubscription);
    const first = source.items[0];
    const body =
      first && typeof first === "object" && "body" in first ? first.body : null;
    return {
      connected: true,
      targetSubscriptions: subscriptions.length,
      sourceSubscriptionRecognized: recognized.success,
      sourceSubscriptionFields:
        sourceSubscription && typeof sourceSubscription === "object"
          ? Object.keys(sourceSubscription)
          : [],
      sourceEventEnvelopeFields:
        first && typeof first === "object" ? Object.keys(first) : [],
      sourceEventFields:
        body && typeof body === "object" ? Object.keys(body) : [],
    };
  } catch (error) {
    return { connected: false, reason: safeReason(error) };
  }
}

function safeReason(error: unknown) {
  // Never log response bodies, authorization headers or user receipt data.
  return error instanceof Error &&
    /^Sandbox RC read failed \(\d{3}\)$/.test(error.message)
    ? error.message
    : "Sandbox verification unavailable";
}

export async function reconcileSandboxCustomer(
  userId: string,
  workspaceId?: string,
) {
  if (!sandboxReconciliationEnabled(userId)) return "disabled";
  const observedAt = new Date().toISOString();
  try {
    const admin = createSupabaseAdminClient();
    if (!admin) return "unavailable";
    const { data: workspace, error: workspaceError } = await admin
      .from("workspaces")
      .select("id,owner_user_id")
      .eq("kind", "personal")
      .eq("owner_user_id", userId)
      .maybeSingle();
    if (
      workspaceError ||
      !workspace ||
      workspace.owner_user_id !== userId ||
      (workspaceId && workspace.id !== workspaceId)
    )
      return "owner_mismatch";
    const subscriptions = await readSubscriptions();
    if (subscriptions.length !== 1) return "no_verified_subscription";
    const subscription = subscriptions[0];
    const purchase = await findPurchase(subscription);
    if (!purchase) return "missing_original_transaction";
    // Ownership must still be current after reading historical transaction proof.
    const confirmation = await readSubscriptions();
    if (
      confirmation.length !== 1 ||
      JSON.stringify(confirmation[0]) !== JSON.stringify(subscription)
    )
      return "snapshot_changed";
    const { data: mapping, error: mappingError } = await admin
      .from("billing_product_mappings")
      .select("plan_id")
      .eq("provider", "apple")
      .eq("store_product_id", product)
      .is("base_plan_id", null)
      .eq("active", true)
      .maybeSingle();
    if (mappingError || !mapping) return "mapping_missing";
    const access =
      subscription.gives_access &&
      subscription.current_period_ends_at > Date.parse(observedAt) &&
      ["active", "trialing", "in_grace_period"].includes(subscription.status);
    const autoRenewing =
      access &&
      ["will_renew", "has_already_renewed", "will_change_product"].includes(
        subscription.auto_renewal_status,
      );
    const status = !access ? "expired" : autoRenewing ? "active" : "cancelled";
    const expiresAt = new Date(
      access
        ? subscription.current_period_ends_at
        : Math.min(subscription.current_period_ends_at, Date.parse(observedAt)),
    ).toISOString();
    const { data: existing, error: existingError } = await admin
      .from("store_purchases")
      .select(
        "user_id,workspace_id,transaction_id,status,expires_at,auto_renewing",
      )
      .eq("provider", "apple")
      .eq("original_transaction_id", purchase.original_transaction_id)
      .maybeSingle();
    if (existingError) return "database_unavailable";
    if (
      existing &&
      existing.user_id === userId &&
      existing.workspace_id === workspace.id &&
      existing.transaction_id === purchase.transaction_id &&
      existing.status === status &&
      Date.parse(existing.expires_at) === Date.parse(expiresAt) &&
      existing.auto_renewing === autoRenewing
    )
      return "unchanged";
    const hash = createHash("sha256")
      .update(JSON.stringify({ subscription, purchase, observedAt }))
      .digest("hex");
    const { data, error } = await admin.rpc("apply_store_billing_event", {
      event_id_input: `sandbox-snapshot:${hash}`,
      event_type_input: "SANDBOX_SERVER_SNAPSHOT",
      payload_hash_input: hash,
      environment_input: "SANDBOX",
      store_provider_input: "apple",
      user_id_input: userId,
      workspace_id_input: workspace.id,
      plan_id_input: mapping.plan_id,
      store_product_id_input: product,
      base_plan_id_input: null,
      transaction_id_input: purchase.transaction_id,
      original_transaction_id_input: purchase.original_transaction_id,
      status_input: status,
      purchased_at_input: new Date(
        subscription.current_period_starts_at,
      ).toISOString(),
      expires_at_input: expiresAt,
      auto_renewing_input: autoRenewing,
      occurred_at_input: observedAt,
    });
    if (error) return "database_unavailable";
    return typeof data === "string" ? data : "verified";
  } catch (error) {
    console.warn("Sandbox billing reconciliation:", safeReason(error));
    return "unavailable";
  }
}
