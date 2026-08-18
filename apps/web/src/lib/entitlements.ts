import type { SupabaseClient } from "@supabase/supabase-js";

/**
 * Plan limiti çözümlemesi ve kota kapısı.
 *
 * Fiyatlar ve limitler ADR-0005'te, kanal/entitlement mimarisi ADR-0004'te
 * tanımlıdır. Bu dosya tek doğruluk kaynağıdır; rotalar limitleri kendileri
 * hesaplamaz, yalnız `assertQuota` çağırır.
 */

/** null = sınırsız. */
export type Limits = {
  companies: number | null;
  aiMinutes: number | null;
  ocr: number | null;
  documentBytes: number | null;
  seats: number;
};

export type Entitlement = {
  planId: string;
  planName: string;
  status: string;
  trialActive: boolean;
  trialEndsAt: string | null;
  seatsPurchased: number;
  periodStart: Date;
  limits: Limits;
  topUp: { aiMinutes: number; ocr: number };
};

export type QuotaKind = "companies" | "ai_minutes" | "ocr" | "seats";

const FREE_PLAN_ID = "free";
/** Denemede kullanıcı bu planın limitlerini görür (ADR-0005: "tam erişim"). */
const TRIAL_PLAN_ID = "individual";
/** past_due durumunda ödeme alınmadan tanınan ek süre (ADR-0004). */
const PAST_DUE_GRACE_DAYS = 7;

type PlanRow = {
  id: string;
  name: string;
  seat_limit: number;
  monthly_ai_minutes: number;
  monthly_document_bytes: number;
  max_companies: number | null;
  max_ocr: number | null;
};

type SubscriptionRow = {
  plan_id: string;
  status: string;
  seat_quantity: number;
  trial_ends_at: string | null;
  current_period_start: string | null;
  current_period_end: string | null;
  plan: PlanRow | null;
};

function startOfMonth(now = new Date()): Date {
  const start = new Date(now);
  start.setUTCDate(1);
  start.setUTCHours(0, 0, 0, 0);
  return start;
}

/**
 * Koltuk başına tanımlı kotayı havuza çevirir. Ekip ve Kurumsal planda bir
 * kullanıcı az, diğeri çok kullanabilir (ADR-0005).
 */
function pooled(perSeat: number | null, seats: number): number | null {
  if (perSeat === null) return null;
  return perSeat * Math.max(seats, 1);
}

function limitsFromPlan(plan: PlanRow, seats: number): Limits {
  return {
    companies: plan.max_companies,
    aiMinutes: pooled(plan.monthly_ai_minutes, seats),
    ocr: pooled(plan.max_ocr, seats),
    documentBytes: plan.monthly_document_bytes,
    seats: plan.seat_limit,
  };
}

const PLAN_COLUMNS =
  "id,name,seat_limit,monthly_ai_minutes,monthly_document_bytes,max_companies,max_ocr";

async function loadPlan(
  supabase: SupabaseClient,
  planId: string,
): Promise<PlanRow | null> {
  const { data } = await supabase
    .from("subscription_plans")
    .select(PLAN_COLUMNS)
    .eq("id", planId)
    .maybeSingle();
  return (data as PlanRow | null) ?? null;
}

/**
 * Ödeme sağlayıcısı bağlanana kadar bile doğru çalışır: abonelik satırı yoksa
 * çalışma alanının oluşturulma tarihinden itibaren 14 gün deneme, sonrası
 * ücretsiz katman kabul edilir.
 */
export async function resolveEntitlement(
  supabase: SupabaseClient,
  workspaceId: string,
  now = new Date(),
): Promise<Entitlement> {
  const [{ data: subscriptionData }, { data: workspaceData }] =
    await Promise.all([
      supabase
        .from("workspace_subscriptions")
        .select(
          `plan_id,status,seat_quantity,trial_ends_at,current_period_start,current_period_end,plan:subscription_plans(${PLAN_COLUMNS})`,
        )
        .eq("workspace_id", workspaceId)
        .maybeSingle(),
      supabase
        .from("workspaces")
        .select("created_at")
        .eq("id", workspaceId)
        .maybeSingle(),
    ]);

  const subscription = subscriptionData as SubscriptionRow | null;
  const seats = Math.max(subscription?.seat_quantity ?? 1, 1);

  const trialEndsAt =
    subscription?.trial_ends_at ??
    (workspaceData?.created_at
      ? new Date(
          new Date(workspaceData.created_at).getTime() +
            14 * 24 * 60 * 60 * 1000,
        ).toISOString()
      : null);

  const status = subscription?.status ?? "trialing";
  const trialActive =
    status === "trialing" &&
    trialEndsAt !== null &&
    new Date(trialEndsAt) > now;

  let effectivePlanId = FREE_PLAN_ID;
  if (trialActive) {
    effectivePlanId = TRIAL_PLAN_ID;
  } else if (status === "active") {
    effectivePlanId = subscription?.plan_id ?? FREE_PLAN_ID;
  } else if (status === "past_due" && subscription?.current_period_end) {
    const graceEnd = new Date(subscription.current_period_end);
    graceEnd.setUTCDate(graceEnd.getUTCDate() + PAST_DUE_GRACE_DAYS);
    if (graceEnd > now) effectivePlanId = subscription.plan_id;
  } else if (status === "cancelled" && subscription?.current_period_end) {
    if (new Date(subscription.current_period_end) > now)
      effectivePlanId = subscription.plan_id;
  }

  const plan =
    (effectivePlanId === subscription?.plan_id ? subscription.plan : null) ??
    (await loadPlan(supabase, effectivePlanId));

  // Plan satırı bulunamazsa en kısıtlayıcı davranış uygulanır; hiçbir koşulda
  // "limit yok" varsayılmaz.
  const limits: Limits = plan
    ? limitsFromPlan(plan, seats)
    : {
        companies: 5,
        aiMinutes: 10,
        ocr: 5,
        documentBytes: 268435456,
        seats: 1,
      };

  const { data: topUpRows } = await supabase
    .from("workspace_ai_topups")
    .select("ai_minutes_granted,ai_minutes_used,ocr_granted,ocr_used")
    .eq("workspace_id", workspaceId);

  const topUp = (topUpRows ?? []).reduce(
    (total, row) => ({
      aiMinutes:
        total.aiMinutes +
        Math.max(
          Number(row.ai_minutes_granted) - Number(row.ai_minutes_used),
          0,
        ),
      ocr:
        total.ocr + Math.max(Number(row.ocr_granted) - Number(row.ocr_used), 0),
    }),
    { aiMinutes: 0, ocr: 0 },
  );

  return {
    planId: plan?.id ?? FREE_PLAN_ID,
    planName: plan?.name ?? "Ücretsiz",
    status,
    trialActive,
    trialEndsAt,
    seatsPurchased: seats,
    periodStart: subscription?.current_period_start
      ? new Date(subscription.current_period_start)
      : startOfMonth(now),
    limits,
    topUp,
  };
}

type QuotaContext = {
  supabase: SupabaseClient;
  workspaceId: string;
  organizationId: string | null;
};

async function measureUsage(
  context: QuotaContext,
  kind: QuotaKind,
  entitlement: Entitlement,
): Promise<number> {
  const { supabase, workspaceId, organizationId } = context;
  const since = entitlement.periodStart.toISOString();

  if (kind === "companies") {
    const { count } = await supabase
      .from("companies")
      .select("id", { count: "exact", head: true })
      .eq("workspace_id", workspaceId)
      .is("archived_at", null);
    return count ?? 0;
  }

  if (kind === "seats") {
    if (!organizationId) return 1;
    const { count } = await supabase
      .from("memberships")
      .select("id", { count: "exact", head: true })
      .eq("organization_id", organizationId)
      .is("revoked_at", null);
    return count ?? 0;
  }

  if (kind === "ocr") {
    const { count } = await supabase
      .from("usage_records")
      .select("id", { count: "exact", head: true })
      .eq("workspace_id", workspaceId)
      .eq("metric", "ocr")
      .gte("occurred_at", since);
    return count ?? 0;
  }

  const { data } = await supabase
    .from("usage_records")
    .select("quantity")
    .eq("workspace_id", workspaceId)
    .eq("metric", "audio_seconds")
    .gte("occurred_at", since);
  const seconds = (data ?? []).reduce(
    (total, row) => total + Number(row.quantity ?? 0),
    0,
  );
  return Math.ceil(seconds / 60);
}

const QUOTA_MESSAGES: Record<QuotaKind, string> = {
  companies:
    "Planınızın müşteri kaydı sınırına ulaştınız. Mevcut kayıtlarınız korunur.",
  ai_minutes:
    "Bu dönemki AI dakikanız doldu. Ek AI paketi alarak devam edebilirsiniz.",
  ocr: "Bu dönemki kartvizit tarama hakkınız doldu.",
  seats:
    "Satın alınan koltuk sayısı doldu. Yeni üye eklemek için koltuk ekleyin.",
};

function limitFor(kind: QuotaKind, entitlement: Entitlement): number | null {
  switch (kind) {
    case "companies":
      return entitlement.limits.companies;
    case "ai_minutes":
      return entitlement.limits.aiMinutes === null
        ? null
        : entitlement.limits.aiMinutes + entitlement.topUp.aiMinutes;
    case "ocr":
      return entitlement.limits.ocr === null
        ? null
        : entitlement.limits.ocr + entitlement.topUp.ocr;
    case "seats":
      return Math.min(entitlement.seatsPurchased, entitlement.limits.seats);
  }
}

/**
 * Kota aşıldıysa `402` yanıtı, aşılmadıysa `null` döner. Yanıt gövdesi makine
 * okunur `code` ve `quota` taşır ki mobil uygulama doğru bilgilendirme ekranını
 * seçebilsin (ADR-0004: kurumsal üyeye satın alma yüzeyi gösterilmez).
 */
export async function assertQuota(
  context: QuotaContext,
  kind: QuotaKind,
  options: { amount?: number; entitlement?: Entitlement } = {},
): Promise<Response | null> {
  const entitlement =
    options.entitlement ??
    (await resolveEntitlement(context.supabase, context.workspaceId));
  const limit = limitFor(kind, entitlement);
  if (limit === null) return null;

  const amount = options.amount ?? 1;
  const used = await measureUsage(context, kind, entitlement);
  if (used + amount <= limit) return null;

  return Response.json(
    {
      error: QUOTA_MESSAGES[kind],
      code: "quota_exceeded",
      quota: kind,
      limit,
      used,
      planId: entitlement.planId,
      trialActive: entitlement.trialActive,
    },
    { status: 402 },
  );
}
