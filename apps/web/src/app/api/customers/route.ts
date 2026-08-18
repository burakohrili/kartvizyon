import { companyCreateSchema } from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";
import { assertQuota } from "@/lib/entitlements";

export async function GET(request: Request) {
  const context = await getApiContext(request);
  if (!context.ok) return context.response;

  const { data, error } = await context.supabase
    .from("companies")
    .select("id,name,phone,email,address,assigned_to,updated_at")
    .eq("workspace_id", context.workspaceId)
    .is("archived_at", null)
    .order("updated_at", { ascending: false })
    .limit(100);
  if (error) return apiError(error);
  return Response.json({ data });
}

export async function POST(request: Request) {
  try {
    const input = companyCreateSchema.parse(await request.json());
    const context = await getApiContext(request);
    if (!context.ok) return context.response;

    // Çalışma alanı istek gövdesinden değil oturumdan gelir; gövdedeki değer
    // yalnız istemci tarafı kolaylığıdır ve yok sayılır.
    const quotaDenied = await assertQuota(context, "companies");
    if (quotaDenied) return quotaDenied;

    const { data, error } = await context.supabase
      .from("companies")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        name: input.name,
        phone: input.phone,
        email: input.email,
        website: input.website,
        address: input.address,
        client_mutation_id: input.clientMutationId,
        created_by: context.user.id,
      })
      .select("id,name,created_at")
      .single();
    if (error) return apiError(error);
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
