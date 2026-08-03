import { orderDraftCreateSchema } from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { data, error } = await context.supabase
      .from("order_drafts")
      .select("*,company:companies(name),items:order_draft_items(*)")
      .eq("workspace_id", context.workspaceId)
      .order("created_at", { ascending: false });
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
    const input = orderDraftCreateSchema.parse(await request.json());
    if (input.workspaceId !== context.workspaceId)
      return Response.json(
        { error: "Çalışma alanı uyuşmuyor." },
        { status: 403 },
      );

    const productIds = input.items.map((item) => item.productId);
    const products = await context.supabase
      .from("products")
      .select("id,tax_rate")
      .eq("workspace_id", context.workspaceId)
      .in("id", productIds);
    if (products.error) throw products.error;
    if ((products.data?.length ?? 0) !== new Set(productIds).size) {
      return Response.json(
        { error: "Ürünlerden biri çalışma alanında bulunamadı." },
        { status: 400 },
      );
    }
    const taxRates = new Map(
      (products.data ?? []).map((product) => [
        product.id,
        Number(product.tax_rate),
      ]),
    );
    const order = await context.supabase
      .from("order_drafts")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        company_id: input.companyId,
        opportunity_id: input.opportunityId ?? null,
        currency: input.currency,
        delivery_date: input.deliveryDate ?? null,
        notes: input.notes ?? null,
        created_by: context.user.id,
      })
      .select("*")
      .single();
    if (order.error || !order.data)
      throw order.error ?? new Error("Sipariş oluşturulamadı.");

    const items = input.items.map((item) => {
      const taxRate = taxRates.get(item.productId) ?? 0;
      const net =
        item.quantity * item.unitPrice * (1 - item.discountPercent / 100);
      return {
        order_draft_id: order.data.id,
        product_id: item.productId,
        quantity: item.quantity,
        unit_price: item.unitPrice,
        discount_percent: item.discountPercent,
        tax_rate: taxRate,
        line_total: Number((net * (1 + taxRate / 100)).toFixed(2)),
      };
    });
    const itemResult = await context.supabase
      .from("order_draft_items")
      .insert(items);
    if (itemResult.error) {
      await context.supabase
        .from("order_drafts")
        .delete()
        .eq("id", order.data.id);
      throw itemResult.error;
    }
    const recalculation = await context.supabase.rpc(
      "recalculate_order_draft",
      {
        target_order_id: order.data.id,
      },
    );
    if (recalculation.error) throw recalculation.error;
    const result = await context.supabase
      .from("order_drafts")
      .select("*,items:order_draft_items(*)")
      .eq("id", order.data.id)
      .single();
    if (result.error) throw result.error;
    return Response.json({ data: result.data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
