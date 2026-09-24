import { companyUpdateSchema } from "@kartvizyon/contracts";
import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";
import { geocodeAddress } from "@/lib/geocoding";

const archiveSchema = z.object({ action: z.literal("archive") });

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { id } = await params;
    const companyId = z.uuid().parse(id);
    const [
      company,
      contacts,
      tasks,
      memory,
      visits,
      contactCount,
      openTaskCount,
      visitCount,
      opportunities,
      orders,
      documents,
    ] = await Promise.all([
      context.supabase
        .from("companies")
        .select("*")
        .eq("id", companyId)
        .eq("workspace_id", context.workspaceId)
        .single(),
      context.supabase
        .from("contacts")
        .select("id,first_name,last_name,title,phone,email")
        .eq("company_id", companyId)
        .eq("workspace_id", context.workspaceId)
        .order("created_at"),
      context.supabase
        .from("tasks")
        .select("id,title,due_at,status")
        .eq("company_id", companyId)
        .eq("workspace_id", context.workspaceId)
        .eq("status", "open")
        .order("due_at"),
      context.supabase
        .from("customer_memory_cards")
        .select("summary,open_promises,source_visit_ids,generated_at")
        .eq("company_id", companyId)
        .maybeSingle(),
      context.supabase
        .from("visits")
        .select("id,approved_at,ai_summary")
        .eq("company_id", companyId)
        .eq("workspace_id", context.workspaceId)
        .eq("status", "approved")
        .order("approved_at", { ascending: false })
        .limit(20),
      context.supabase
        .from("contacts")
        .select("id", { count: "exact", head: true })
        .eq("company_id", companyId)
        .eq("workspace_id", context.workspaceId),
      context.supabase
        .from("tasks")
        .select("id", { count: "exact", head: true })
        .eq("company_id", companyId)
        .eq("workspace_id", context.workspaceId)
        .eq("status", "open"),
      context.supabase
        .from("visits")
        .select("id", { count: "exact", head: true })
        .eq("company_id", companyId)
        .eq("workspace_id", context.workspaceId),
      context.supabase
        .from("opportunities")
        .select("id", { count: "exact", head: true })
        .eq("company_id", companyId)
        .eq("workspace_id", context.workspaceId),
      context.supabase
        .from("order_drafts")
        .select("id", { count: "exact", head: true })
        .eq("company_id", companyId)
        .eq("workspace_id", context.workspaceId),
      context.supabase
        .from("documents")
        .select("id", { count: "exact", head: true })
        .eq("company_id", companyId)
        .eq("workspace_id", context.workspaceId),
    ]);
    if (company.error) throw company.error;
    if (contacts.error) throw contacts.error;
    if (tasks.error) throw tasks.error;
    if (memory.error) throw memory.error;
    if (visits.error) throw visits.error;
    if (contactCount.error) throw contactCount.error;
    if (openTaskCount.error) throw openTaskCount.error;
    if (visitCount.error) throw visitCount.error;
    if (opportunities.error) throw opportunities.error;
    if (orders.error) throw orders.error;
    if (documents.error) throw documents.error;
    return Response.json({
      company: company.data,
      contacts: contacts.data,
      tasks: tasks.data,
      memory: memory.data,
      visits: visits.data,
      dependencies: {
        contacts: contactCount.count ?? 0,
        visits: visitCount.count ?? 0,
        openTasks: openTaskCount.count ?? 0,
        opportunities: opportunities.count ?? 0,
        orders: orders.count ?? 0,
        documents: documents.count ?? 0,
      },
    });
  } catch (error) {
    return apiError(error);
  }
}

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const companyId = z.uuid().parse((await params).id);
    const body: unknown = await request.json();
    if (archiveSchema.safeParse(body).success) {
      const { data, error } = await context.supabase
        .from("companies")
        .update({
          archived_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq("id", companyId)
        .eq("workspace_id", context.workspaceId)
        .is("archived_at", null)
        .select("id")
        .maybeSingle();
      if (error) throw error;
      if (!data)
        return Response.json({ error: "Müşteri bulunamadı." }, { status: 404 });
      return Response.json({ archived: true });
    }
    const input = companyUpdateSchema.parse({
      ...(body as object),
      id: companyId,
    });
    const current = await context.supabase
      .from("companies")
      .select("address")
      .eq("id", companyId)
      .eq("workspace_id", context.workspaceId)
      .is("archived_at", null)
      .maybeSingle();
    if (current.error) throw current.error;
    if (!current.data)
      return Response.json({ error: "Müşteri bulunamadı." }, { status: 404 });
    const addressChanged =
      (current.data.address ?? "") !== (input.address ?? "");
    const coordinates =
      addressChanged && input.address
        ? await geocodeAddress(input.address)
        : null;
    const update: Record<string, unknown> = {
      name: input.name,
      display_name: input.displayName ?? null,
      address: input.address ?? null,
      phone: input.phone ?? null,
      email: input.email ?? null,
      website: input.website ?? null,
      updated_at: new Date().toISOString(),
    };
    if (addressChanged)
      Object.assign(update, {
        latitude: coordinates?.latitude ?? null,
        longitude: coordinates?.longitude ?? null,
        location_source: coordinates ? "geocoded" : null,
        location_updated_at: new Date().toISOString(),
      });
    const { data, error } = await context.supabase
      .from("companies")
      .update(update)
      .eq("id", companyId)
      .eq("workspace_id", context.workspaceId)
      .select("*")
      .maybeSingle();
    if (error) throw error;
    if (!data)
      return Response.json({ error: "Müşteri bulunamadı." }, { status: 404 });
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}
