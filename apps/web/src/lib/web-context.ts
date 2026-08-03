import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getSelectedWorkspaceId } from "@/lib/reports";

export async function getWebWorkspaceContext() {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return null;
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;
  let workspaceId = await getSelectedWorkspaceId();
  if (!workspaceId || workspaceId.startsWith("demo-")) {
    const first = await supabase
      .from("workspaces")
      .select("id,organization_id")
      .limit(1)
      .single();
    workspaceId = first.data?.id ?? null;
  }
  if (!workspaceId) return null;
  const workspace = await supabase
    .from("workspaces")
    .select("id,organization_id")
    .eq("id", workspaceId)
    .single();
  if (!workspace.data) return null;
  return {
    supabase,
    user,
    workspaceId,
    organizationId: workspace.data.organization_id as string | null,
  };
}
