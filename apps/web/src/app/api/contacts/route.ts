import { contactCreateSchema } from "@kartvizyon/contracts";
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
  const companyId = new URL(request.url).searchParams.get("companyId");
  if (!companyId)
    return Response.json({ error: "companyId gerekli." }, { status: 400 });
  const { data, error } = await supabase
    .from("contacts")
    .select("id,first_name,last_name,title,phone,email,preferred_channel")
    .eq("company_id", companyId)
    .order("created_at");
  if (error) return apiError(error);
  return Response.json({ data });
}

export async function POST(request: Request) {
  try {
    const input = contactCreateSchema.parse(await request.json());
    const supabase = await createSupabaseServerClient(request);
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });
    const { data, error } = await supabase
      .from("contacts")
      .insert({
        company_id: input.companyId,
        workspace_id: input.workspaceId,
        organization_id: input.organizationId,
        first_name: input.firstName,
        last_name: input.lastName,
        title: input.title,
        phone: input.phone,
        email: input.email,
        created_by: user.id,
      })
      .select("id,first_name,last_name")
      .single();
    if (error) return apiError(error);
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
