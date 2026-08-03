import { cookies } from "next/headers";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const supabase = await createSupabaseServerClient(request);
  if (!supabase)
    return Response.json({
      ownerId: "demo-local",
      workspaceId: "00000000-0000-4000-8000-000000000001",
      organizationId: null,
    });
  const { data } = await supabase.auth.getUser();
  if (!data.user)
    return Response.json({ error: "Oturum gerekli." }, { status: 401 });
  let workspaceId =
    (await cookies()).get("kartvizyon_workspace")?.value ?? null;
  let workspace: { id: string; organization_id: string | null } | null = null;
  if (workspaceId && !workspaceId.startsWith("demo-")) {
    const selected = await supabase
      .from("workspaces")
      .select("id,organization_id")
      .eq("id", workspaceId)
      .maybeSingle();
    workspace = selected.data;
  }
  if (!workspace) {
    const first = await supabase
      .from("workspaces")
      .select("id,organization_id")
      .limit(1)
      .maybeSingle();
    workspace = first.data;
  }
  return Response.json({
    ownerId: data.user.id,
    workspaceId: workspace?.id ?? null,
    organizationId: workspace?.organization_id ?? null,
  });
}
