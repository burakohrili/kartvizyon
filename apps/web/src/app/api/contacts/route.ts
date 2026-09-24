import {
  contactCreateSchema,
  contactUpdateSchema,
} from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  const context = await getApiContext(request);
  if (!context.ok) return context.response;
  const companyId = new URL(request.url).searchParams.get("companyId");
  if (!companyId)
    return Response.json({ error: "companyId gerekli." }, { status: 400 });
  const { data, error } = await context.supabase
    .from("contacts")
    .select("id,first_name,last_name,title,phone,email,preferred_channel")
    .eq("company_id", companyId)
    .eq("workspace_id", context.workspaceId)
    .order("created_at");
  if (error) return apiError(error);
  return Response.json({ data });
}

export async function POST(request: Request) {
  try {
    const input = contactCreateSchema.parse(await request.json());
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const company = await context.supabase
      .from("companies")
      .select("id")
      .eq("id", input.companyId)
      .eq("workspace_id", context.workspaceId)
      .is("archived_at", null)
      .maybeSingle();
    if (company.error) throw company.error;
    if (!company.data)
      return Response.json({ error: "Müşteri bulunamadı." }, { status: 404 });
    const { data, error } = await context.supabase
      .from("contacts")
      .insert({
        company_id: input.companyId,
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        first_name: input.firstName,
        last_name: input.lastName ?? null,
        title: input.title ?? null,
        phone: input.phone ?? null,
        email: input.email ?? null,
        created_by: context.user.id,
      })
      .select("id,first_name,last_name,title,phone,email")
      .single();
    if (error) return apiError(error);
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}

export async function PATCH(request: Request) {
  try {
    const input = contactUpdateSchema.parse(await request.json());
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { data, error } = await context.supabase
      .from("contacts")
      .update({
        first_name: input.firstName,
        last_name: input.lastName,
        title: input.title,
        phone: input.phone,
        email: input.email,
      })
      .eq("id", input.id)
      .eq("workspace_id", context.workspaceId)
      .select("id,first_name,last_name,title,phone,email")
      .maybeSingle();
    if (error) throw error;
    if (!data)
      return Response.json(
        { error: "İlgili kişi bulunamadı." },
        { status: 404 },
      );
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}
