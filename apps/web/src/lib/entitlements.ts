import type { SupabaseClient } from "@supabase/supabase-js";
import { z } from "zod";

const limit = z.number().nonnegative().nullable();
const entitlementSchema = z.object({
  planId: z.string(),
  planName: z.string(),
  status: z.string(),
  readOnly: z.boolean(),
  trialActive: z.boolean(),
  trialEndsAt: z.string().nullable(),
  accessEndsAt: z.string().nullable(),
  seatsPurchased: z.number().int().positive(),
  periodStart: z
    .string()
    .datetime({ offset: true })
    .transform((value) => new Date(value)),
  limits: z.object({
    companies: limit,
    aiMinutes: limit,
    ocr: limit,
    aiSummaries: limit,
    documentBytes: limit,
    seats: z.number().int().positive(),
  }),
  topUp: z.object({ aiMinutes: z.number(), ocr: z.number() }),
});
export type Entitlement = z.infer<typeof entitlementSchema>;
export type Limits = Entitlement["limits"];
export type QuotaKind =
  | "companies"
  | "ai_minutes"
  | "ocr"
  | "ai_summaries"
  | "storage_bytes"
  | "seats";
type QuotaContext = {
  supabase: SupabaseClient;
  workspaceId: string;
  organizationId: string | null;
};

// Haklar tek merkezde SQL tarafından, sunucu saatiyle çözümlenir. Hata halinde
// ücretsiz hak veya yeni deneme üretmek yerine işlem kapalı kalır.
export async function resolveEntitlement(
  supabase: SupabaseClient,
  workspaceId: string,
): Promise<Entitlement> {
  const { data, error } = await supabase.rpc("workspace_entitlement", {
    workspace_id_input: workspaceId,
  });
  if (error) throw error;
  return entitlementSchema.parse(data);
}
export function subscriptionRequired() {
  return Response.json(
    {
      code: "subscription_required",
      error:
        "Devam etmek için abonelik başlatın. Mevcut kayıtları görüntüleme, dışa aktarma ve hesap silme açık.",
    },
    { status: 402 },
  );
}
export async function assertWorkspaceWritable(
  supabase: SupabaseClient,
  workspaceId: string,
) {
  const entitlement = await resolveEntitlement(supabase, workspaceId);
  return entitlement.readOnly ? subscriptionRequired() : null;
}
export async function readUsage(
  supabase: SupabaseClient,
  workspaceId: string,
): Promise<Record<string, number>> {
  const { data, error } = await supabase.rpc("workspace_usage", {
    workspace_id_input: workspaceId,
  });
  if (error) throw error;
  return z.record(z.string(), z.number().nonnegative()).parse(data);
}
export async function assertQuota(
  context: QuotaContext,
  kind: QuotaKind,
  options: { amount?: number; entitlement?: Entitlement } = {},
): Promise<Response | null> {
  const entitlement =
    options.entitlement ??
    (await resolveEntitlement(context.supabase, context.workspaceId));
  if (entitlement.readOnly) return subscriptionRequired();
  const amount = options.amount ?? 1;
  if (!Number.isFinite(amount) || amount < 0)
    throw new Error("Invalid quota amount");
  const limits = entitlement.limits;
  const allowance = {
    companies: limits.companies,
    ai_minutes: limits.aiMinutes,
    ocr: limits.ocr,
    ai_summaries: limits.aiSummaries,
    storage_bytes: limits.documentBytes,
    seats: Math.min(entitlement.seatsPurchased, limits.seats),
  }[kind];
  if (allowance === null) return null;
  let used = 0;
  if (kind === "companies" || kind === "seats") {
    if (kind === "seats" && !context.organizationId) used = 1;
    else {
      const result = await context.supabase
        .from(kind === "companies" ? "companies" : "memberships")
        .select("id", { count: "exact", head: true })
        .eq(
          kind === "companies" ? "workspace_id" : "organization_id",
          kind === "companies" ? context.workspaceId : context.organizationId,
        )
        .is(kind === "companies" ? "archived_at" : "revoked_at", null);
      if (result.error) throw result.error;
      used = result.count ?? 0;
    }
  } else if (kind === "storage_bytes") {
    // Sayfalama, PostgREST satır sınırının depolama kotasını eksik saymasını önler.
    for (let offset = 0; ; offset += 500) {
      const result = await context.supabase
        .from("documents")
        .select("size_bytes")
        .eq("workspace_id", context.workspaceId)
        .order("id")
        .range(offset, offset + 499);
      if (result.error) throw result.error;
      used += (result.data ?? []).reduce(
        (n, row) => n + Number(row.size_bytes),
        0,
      );
      if ((result.data?.length ?? 0) < 500) break;
    }
  } else {
    const usage = await readUsage(context.supabase, context.workspaceId);
    used =
      kind === "ai_minutes"
        ? (usage.audio_seconds ?? 0) / 60
        : (usage[kind === "ai_summaries" ? "ai_summary" : "ocr"] ?? 0);
  }
  if (used + amount <= allowance) return null;
  return Response.json(
    {
      error:
        "Bu dönemki kullanım hakkınız doldu. Denemedeyseniz abonelik başlatabilirsiniz.",
      code: "quota_exceeded",
      quota: kind,
      used,
      limit: allowance,
      trialActive: entitlement.trialActive,
    },
    { status: 402 },
  );
}
