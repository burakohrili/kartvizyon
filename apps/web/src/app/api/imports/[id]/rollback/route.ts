import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function POST(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  if (!supabase) return serviceUnavailable();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return Response.json({ error: "Oturum gerekli." }, { status: 401 });
  const { data: job, error: jobError } = await supabase
    .from("import_jobs")
    .select("id,status,workspace_id,created_company_ids")
    .eq("id", id)
    .eq("created_by", user.id)
    .single();
  if (jobError) return apiError(jobError);
  if (job.status !== "completed")
    return Response.json(
      { error: "Yalnızca tamamlanmış aktarımlar geri alınabilir." },
      { status: 409 },
    );
  const ids = (job.created_company_ids as string[] | null) ?? [];
  if (ids.length > 0) {
    const { error } = await supabase
      .from("companies")
      .delete()
      .in("id", ids)
      .eq("workspace_id", job.workspace_id);
    if (error)
      return Response.json(
        {
          error:
            "Aktarılan firmalara bağlı ziyaretler bulunduğu için geri alma yapılamadı.",
        },
        { status: 409 },
      );
  }
  const { error: updateError } = await supabase
    .from("import_jobs")
    .update({ status: "rolled_back", rolled_back_at: new Date().toISOString() })
    .eq("id", id)
    .eq("created_by", user.id);
  if (updateError) return apiError(updateError);
  return Response.json({
    data: { id, status: "rolled_back", removedCompanies: ids.length },
  });
}
