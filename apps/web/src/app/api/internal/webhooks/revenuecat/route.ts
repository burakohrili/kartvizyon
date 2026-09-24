import { createHash } from "node:crypto";
import {
  dateFromMs,
  lifecycleFor,
  normalizeStore,
  revenueCatUserIds,
  revenueCatUuidIds,
  revenueCatWebhookSchema,
  secureHeaderEquals,
  splitStoreProduct,
  verifyRevenueCatSignature,
} from "@/lib/billing/revenuecat";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

export async function POST(request: Request) {
  const authorizationSecret = process.env.REVENUECAT_WEBHOOK_AUTHORIZATION;
  const signingSecret = process.env.REVENUECAT_WEBHOOK_SIGNING_SECRET;
  const allowedEnvironment = process.env.REVENUECAT_ALLOWED_ENVIRONMENT;
  if (
    !authorizationSecret ||
    !signingSecret ||
    !["PRODUCTION", "SANDBOX"].includes(allowedEnvironment ?? "")
  ) {
    return Response.json(
      { error: "Webhook yapılandırılmamış." },
      { status: 503 },
    );
  }

  const rawBody = await request.text();
  if (
    !secureHeaderEquals(
      request.headers.get("authorization"),
      authorizationSecret,
    ) ||
    !verifyRevenueCatSignature(
      rawBody,
      request.headers.get("x-revenuecat-webhook-signature"),
      signingSecret,
    )
  ) {
    return Response.json(
      { error: "Geçersiz webhook imzası." },
      { status: 401 },
    );
  }

  let payload: unknown;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return Response.json({ error: "Geçersiz JSON." }, { status: 400 });
  }
  const parsed = revenueCatWebhookSchema.safeParse(payload);
  if (!parsed.success)
    return Response.json(
      { error: "Geçersiz webhook gövdesi." },
      { status: 400 },
    );

  const event = parsed.data.event;
  if (event.type === "TEST")
    return Response.json({ received: true, test: true });
  if (event.environment && event.environment !== allowedEnvironment) {
    return Response.json(
      { received: true, ignored: true, reason: "environment_mismatch" },
      { status: 202 },
    );
  }
  if (event.type === "TRANSFER") {
    const provider = normalizeStore(event.store);
    const fromIds = revenueCatUuidIds(event.transferred_from);
    const toIds = revenueCatUuidIds(event.transferred_to);
    if (!provider || !event.environment || !fromIds.length || !toIds.length)
      return Response.json({ error: "Eksik transfer alanı." }, { status: 400 });
    const admin = createSupabaseAdminClient();
    if (!admin)
      return Response.json(
        { error: "Sunucu yapılandırılmamış." },
        { status: 503 },
      );
    const { data: workspaces, error: workspaceError } = await admin
      .from("workspaces")
      .select("id,owner_user_id")
      .eq("kind", "personal")
      .in("owner_user_id", [...fromIds, ...toIds]);
    if (workspaceError) throw workspaceError;
    const fromWorkspace = (workspaces ?? []).find((candidate) =>
      fromIds.includes(candidate.owner_user_id),
    );
    const toWorkspace = (workspaces ?? []).find((candidate) =>
      toIds.includes(candidate.owner_user_id),
    );
    if (!fromWorkspace || !toWorkspace)
      return Response.json(
        { error: "Transfer eşlemesi bulunamadı." },
        { status: 422 },
      );
    const { data, error } = await admin.rpc(
      "transfer_store_billing_ownership",
      {
        event_id_input: event.id,
        payload_hash_input: createHash("sha256").update(rawBody).digest("hex"),
        environment_input: event.environment,
        store_provider_input: provider,
        from_user_id_input: fromWorkspace.owner_user_id,
        from_workspace_id_input: fromWorkspace.id,
        to_user_id_input: toWorkspace.owner_user_id,
        to_workspace_id_input: toWorkspace.id,
        occurred_at_input: dateFromMs(event.event_timestamp_ms),
      },
    );
    if (error) throw error;
    return Response.json({ received: true, outcome: data });
  }
  const lifecycle = lifecycleFor(event);
  if (!lifecycle) return Response.json({ received: true, ignored: true });

  const provider = normalizeStore(event.store);
  const userIds = revenueCatUserIds(event);
  if (
    !provider ||
    userIds.length === 0 ||
    !event.product_id ||
    !event.transaction_id ||
    !event.original_transaction_id ||
    !event.environment
  ) {
    return Response.json({ error: "Eksik abonelik alanı." }, { status: 400 });
  }

  const admin = createSupabaseAdminClient();
  if (!admin)
    return Response.json(
      { error: "Sunucu yapılandırılmamış." },
      { status: 503 },
    );

  const product = splitStoreProduct(event.product_id, provider);
  const [{ data: workspace }, { data: mappings, error: mappingError }] =
    await Promise.all([
      admin
        .from("workspaces")
        .select("id,owner_user_id")
        .eq("kind", "personal")
        .in("owner_user_id", userIds),
      admin
        .from("billing_product_mappings")
        .select("plan_id,base_plan_id")
        .eq("provider", provider)
        .eq("store_product_id", product.productId)
        .eq("active", true),
    ]);
  if (mappingError) throw mappingError;
  const mapping = (mappings ?? []).find(
    (candidate) =>
      candidate.base_plan_id === product.basePlanId ||
      (candidate.base_plan_id == null && product.basePlanId == null),
  );
  const ownerWorkspace = userIds
    .map((userId) =>
      (workspace ?? []).find((candidate) => candidate.owner_user_id === userId),
    )
    .find(Boolean);
  if (!ownerWorkspace || !mapping)
    return Response.json(
      { error: "Abonelik eşlemesi bulunamadı." },
      { status: 422 },
    );

  const { data, error } = await admin.rpc("apply_store_billing_event", {
    event_id_input: event.id,
    event_type_input: event.type,
    payload_hash_input: createHash("sha256").update(rawBody).digest("hex"),
    environment_input: event.environment,
    store_provider_input: provider,
    user_id_input: ownerWorkspace.owner_user_id,
    workspace_id_input: ownerWorkspace.id,
    plan_id_input: mapping.plan_id,
    store_product_id_input: product.productId,
    base_plan_id_input: product.basePlanId,
    transaction_id_input: event.transaction_id,
    original_transaction_id_input: event.original_transaction_id,
    status_input: lifecycle.status,
    purchased_at_input: dateFromMs(event.purchased_at_ms),
    expires_at_input: dateFromMs(
      event.grace_period_expiration_at_ms ?? event.expiration_at_ms,
    ),
    auto_renewing_input: lifecycle.autoRenewing,
    occurred_at_input: dateFromMs(event.event_timestamp_ms),
  });
  if (error) throw error;
  return Response.json({ received: true, outcome: data });
}
