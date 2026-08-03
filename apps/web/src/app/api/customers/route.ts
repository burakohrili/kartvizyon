import { companyCreateSchema } from "@kartvizyon/contracts";
import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const supabase = await createSupabaseServerClient(request);
  if (!supabase) return serviceUnavailable();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return Response.json({ error: "Oturum gerekli." }, { status: 401 });

  const workspaceId = new URL(request.url).searchParams.get("workspaceId");
  if (!workspaceId)
    return Response.json({ error: "workspaceId gerekli." }, { status: 400 });

  const { data, error } = await supabase
    .from("companies")
    .select("id,name,phone,email,address,assigned_to,updated_at")
    .eq("workspace_id", workspaceId)
    .is("archived_at", null)
    .order("updated_at", { ascending: false })
    .limit(100);
  if (error) return apiError(error);
  return Response.json({ data });
}

export async function POST(request: Request) {
  try {
    const input = companyCreateSchema.parse(await request.json());
    const supabase = await createSupabaseServerClient(request);
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });

    const { data, error } = await supabase
      .from("companies")
      .insert({
        workspace_id: input.workspaceId,
        organization_id: input.organizationId,
        name: input.name,
        phone: input.phone,
        email: input.email,
        website: input.website,
        address: input.address,
        client_mutation_id: input.clientMutationId,
        created_by: user.id,
      })
      .select("id,name,created_at")
      .single();
    if (error) return apiError(error);
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
