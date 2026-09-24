import {
  orderDraftCreateSchema,
  orderDraftUpdateSchema,
} from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { data, error } = await context.supabase
      .from("order_drafts")
      .select(
        "*,company:companies(id,name,display_name,address),items:order_draft_items(*,product:products(id,name,sku,currency,unit,tax_rate))",
      )
      .eq("workspace_id", context.workspaceId)
      .order("created_at", { ascending: false });
    if (error) throw error;
    let canApprove = false;
    if (context.organizationId) {
      const membership = await context.supabase
        .from("memberships")
        .select("role")
        .eq("organization_id", context.organizationId)
        .eq("user_id", context.user.id)
        .maybeSingle();
      canApprove = ["owner", "sales_director", "regional_manager"].includes(
        membership.data?.role ?? "",
      );
    }
    const actorIds = [
      ...new Set(
        (data ?? [])
          .map((order) => order.approved_by as string | null)
          .filter((id): id is string => Boolean(id)),
      ),
    ];
    const profiles = actorIds.length
      ? await context.supabase
          .from("profiles")
          .select("id,full_name")
          .in("id", actorIds)
      : { data: [] };
    const actorNames = new Map(
      (profiles.data ?? []).map((profile) => [profile.id, profile.full_name]),
    );
    return Response.json({
      data: (data ?? []).map((order) => ({
        ...order,
        decision_actor_name: order.approved_by
          ? (actorNames.get(order.approved_by) ?? null)
          : null,
      })),
      canApprove,
    });
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

    const customer = await context.supabase
      .from("companies")
      .select("id")
      .eq("id", input.companyId)
      .eq("workspace_id", context.workspaceId)
      .is("archived_at", null)
      .maybeSingle();
    if (customer.error) throw customer.error;
    if (!customer.data)
      return Response.json(
        { error: "Müşteri bulunamadı veya arşivlenmiş." },
        { status: 400 },
      );

    const productIds = input.items.map((item) => item.productId);
    const products = await context.supabase
      .from("products")
      .select("id,tax_rate,currency,active")
      .eq("workspace_id", context.workspaceId)
      .in("id", productIds);
    if (products.error) throw products.error;
    if (
      (products.data?.length ?? 0) !== new Set(productIds).size ||
      products.data?.some(
        (product) => !product.active || product.currency !== input.currency,
      )
    ) {
      return Response.json(
        { error: "Ürünlerden biri aktif değil veya para birimi uyuşmuyor." },
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

export async function PATCH(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = orderDraftUpdateSchema.parse(await request.json());
    const current = await context.supabase
      .from("order_drafts")
      .select("id,status")
      .eq("id", input.id)
      .eq("workspace_id", context.workspaceId)
      .single();
    if (current.error || !current.data)
      return Response.json(
        { error: "Sipariş taslağı bulunamadı." },
        { status: 404 },
      );
    if (current.data.status === "rejected") {
      const reset = await context.supabase.rpc("transition_order_draft", {
        target_order_id: input.id,
        target_status: "draft",
        rejection_reason: null,
      });
      if (reset.error) throw reset.error;
    } else if (current.data.status !== "draft") {
      return Response.json(
        { error: "Yalnız taslak veya reddedilmiş sipariş düzenlenebilir." },
        { status: 409 },
      );
    }
    const updated = await context.supabase.rpc("update_order_draft", {
      target_order_id: input.id,
      target_company_id: input.companyId,
      target_opportunity_id: input.opportunityId ?? null,
      target_delivery_date: input.deliveryDate ?? null,
      target_notes: input.notes ?? null,
      target_currency: input.currency,
      target_items: input.items,
    });
    if (updated.error) throw updated.error;
    const result = await context.supabase
      .from("order_drafts")
      .select("*,items:order_draft_items(*)")
      .eq("id", input.id)
      .single();
    if (result.error) throw result.error;
    return Response.json({ data: result.data });
  } catch (error) {
    return apiError(error);
  }
}
