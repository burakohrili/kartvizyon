import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ companyId: string }> },
) {
  const { companyId } = await params;
  const supabase = await createSupabaseServerClient();
  if (!supabase) return serviceUnavailable();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return Response.json({ error: "Oturum gerekli." }, { status: 401 });
  const [
    { data: company, error: companyError },
    { data: memory },
    { data: tasks },
    { data: visits },
  ] = await Promise.all([
    supabase
      .from("companies")
      .select("id,name,address")
      .eq("id", companyId)
      .single(),
    supabase
      .from("customer_memory_cards")
      .select("summary,open_promises,source_visit_ids,generated_at,stale_after")
      .eq("company_id", companyId)
      .maybeSingle(),
    supabase
      .from("tasks")
      .select("id,title,due_at")
      .eq("company_id", companyId)
      .eq("status", "open")
      .order("due_at")
      .limit(5),
    supabase
      .from("visits")
      .select("id,approved_at")
      .eq("company_id", companyId)
      .eq("status", "approved")
      .order("approved_at", { ascending: false })
      .limit(1),
  ]);
  if (companyError) return apiError(companyError);
  return Response.json({
    data: {
      company,
      memory,
      openTasks: tasks ?? [],
      lastApprovedVisit: visits?.[0] ?? null,
      generatedWithoutLlm: true,
    },
  });
}
