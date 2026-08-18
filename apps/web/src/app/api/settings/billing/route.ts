import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";
import { resolveEntitlement } from "@/lib/entitlements";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const periodStart = new Date();
    periodStart.setUTCDate(1);
    periodStart.setUTCHours(0, 0, 0, 0);
    const [plans, subscription, usage, members] = await Promise.all([
      context.supabase
        .from("subscription_plans")
        .select("*")
        .eq("active", true)
        .order("monthly_price_try"),
      context.supabase
        .from("workspace_subscriptions")
        .select("*,plan:subscription_plans(*)")
        .eq("workspace_id", context.workspaceId)
        .maybeSingle(),
      context.supabase
        .from("usage_records")
        .select("metric,quantity")
        .eq("workspace_id", context.workspaceId)
        .gte("occurred_at", periodStart.toISOString()),
      context.organizationId
        ? context.supabase
            .from("memberships")
            .select("id", { count: "exact", head: true })
            .eq("organization_id", context.organizationId)
            .is("revoked_at", null)
        : Promise.resolve({ count: 1, error: null }),
    ]);
    if (plans.error) throw plans.error;
    if (subscription.error) throw subscription.error;
    if (usage.error) throw usage.error;
    if (members.error) throw members.error;
    const totals = (usage.data ?? []).reduce<Record<string, number>>(
      (all, row) => {
        all[row.metric] = (all[row.metric] ?? 0) + Number(row.quantity);
        return all;
      },
      {},
    );
    // Çözümlenmiş hak, kotayı uygulayan `assertQuota` ile aynı kaynaktan gelir;
    // ekranda gösterilen limitle fiilen uygulanan limit ayrışamaz.
    const entitlement = await resolveEntitlement(
      context.supabase,
      context.workspaceId,
    );

    const { data: topUpPackages } = await context.supabase
      .from("ai_topup_packages")
      .select("id,name,price_try,ai_minutes,ocr_count")
      .eq("active", true)
      .order("price_try");

    return Response.json({
      plans: plans.data,
      subscription: subscription.data,
      usage: totals,
      seatsUsed: members.count ?? 0,
      entitlement,
      topUpPackages: topUpPackages ?? [],
    });
  } catch (error) {
    return apiError(error);
  }
}
