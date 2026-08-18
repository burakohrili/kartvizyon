import { apiError } from "@/lib/api";
import { hasInternalSecret } from "@/lib/internal-auth";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

/**
 * Süresi dolan denemeleri ücretsiz katmana düşürür (ADR-0005).
 *
 * Veri silinmez ve mevcut kayıtlar okunabilir kalır; yalnız yeni kayıt
 * oluşturma limiti devreye girer.
 */
async function expireTrials(request: Request) {
  if (!hasInternalSecret(request, "CRON_SECRET")) {
    return Response.json({ error: "Yetkisiz." }, { status: 401 });
  }

  const supabase = createSupabaseAdminClient();
  if (!supabase) {
    return Response.json(
      { error: "Abonelik servisi yapılandırılmadı." },
      { status: 503 },
    );
  }

  try {
    const now = new Date().toISOString();
    const { data, error } = await supabase
      .from("workspace_subscriptions")
      .update({ plan_id: "free", status: "active", updated_at: now })
      .eq("status", "trialing")
      .lt("trial_ends_at", now)
      .select("workspace_id");
    if (error) throw error;
    return Response.json({ expired: data?.length ?? 0 });
  } catch (error) {
    return apiError(error);
  }
}

export async function GET(request: Request) {
  return expireTrials(request);
}

export async function POST(request: Request) {
  return expireTrials(request);
}
