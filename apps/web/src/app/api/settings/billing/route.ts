import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";
import { resolveEntitlement, readUsage } from "@/lib/entitlements";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const entitlement = await resolveEntitlement(
      context.supabase,
      context.workspaceId,
    );
    const totals = await readUsage(context.supabase, context.workspaceId);
    const [plans, subscription, members, workspace] = await Promise.all([
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
      context.organizationId
        ? context.supabase
            .from("memberships")
            .select("id", { count: "exact", head: true })
            .eq("organization_id", context.organizationId)
            .is("revoked_at", null)
        : Promise.resolve({ count: 1, error: null }),
      context.supabase
        .from("workspaces")
        .select("kind")
        .eq("id", context.workspaceId)
        .single(),
    ]);
    if (plans.error) throw plans.error;
    if (subscription.error) throw subscription.error;
    if (members.error) throw members.error;
    if (workspace.error) throw workspace.error;
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
      workspaceKind: workspace.data.kind,
    });
  } catch (error) {
    return apiError(error);
  }
}
