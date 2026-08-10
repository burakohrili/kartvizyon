import { serviceUnavailable, apiError } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const supabase = await createSupabaseServerClient(request);
  if (!supabase)
    return Response.json({
      data: [
        {
          id: "demo-personal",
          name: "Kişisel Alanım",
          kind: "personal",
          organization_id: null,
        },
        {
          id: "demo-team",
          name: "Vizyon Satış A.Ş.",
          kind: "organization",
          organization_id: "demo-organization",
        },
      ],
      demo: true,
    });
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return Response.json({ error: "Oturum gerekli." }, { status: 401 });
  const { data, error } = await supabase
    .from("workspaces")
    .select("id,name,kind,organization_id")
    .order("created_at");
  if (error) return apiError(error);
  return Response.json({ data });
}

export async function POST(request: Request) {
  const supabase = await createSupabaseServerClient(request);
  if (!supabase) return serviceUnavailable();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return Response.json({ error: "Oturum gerekli." }, { status: 401 });
  const body = (await request.json()) as { name?: string; slug?: string };
  if (!body.name || !body.slug)
    return Response.json(
      { error: "Şirket adı ve kısa adı gerekli." },
      { status: 400 },
    );
  const { data, error } = await supabase.rpc("create_organization", {
    organization_name: body.name,
    organization_slug: body.slug,
  });
  if (error) return apiError(error);
  return Response.json({ data: { organizationId: data } }, { status: 201 });
}
