import { productCreateSchema } from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { data, error } = await context.supabase
      .from("products")
      .select("*")
      .eq("workspace_id", context.workspaceId)
      .eq("active", true)
      .order("name");
    if (error) throw error;
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = productCreateSchema.parse(await request.json());
    if (input.workspaceId !== context.workspaceId)
      return Response.json(
        { error: "Çalışma alanı uyuşmuyor." },
        { status: 403 },
      );
    const { data, error } = await context.supabase
      .from("products")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        sku: input.sku,
        name: input.name,
        unit: input.unit,
        tax_rate: input.taxRate,
        list_price: input.listPrice,
        currency: input.currency,
        created_by: context.user.id,
      })
      .select("*")
      .single();
    if (error) throw error;
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
