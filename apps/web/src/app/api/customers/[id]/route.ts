import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { id } = await params;
    const companyId = z.uuid().parse(id);
    const [company, contacts, tasks, memory, visits] = await Promise.all([
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
    ]);
    if (company.error) throw company.error;
    if (contacts.error) throw contacts.error;
    if (tasks.error) throw tasks.error;
    if (memory.error) throw memory.error;
    if (visits.error) throw visits.error;
    return Response.json({
      company: company.data,
      contacts: contacts.data,
      tasks: tasks.data,
      memory: memory.data,
      visits: visits.data,
    });
  } catch (error) {
    return apiError(error);
  }
}
