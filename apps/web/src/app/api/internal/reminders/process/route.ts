import { apiError } from "@/lib/api";
import { hasInternalSecret } from "@/lib/internal-auth";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

async function processReminders(request: Request) {
  if (!hasInternalSecret(request, "CRON_SECRET")) {
    return Response.json({ error: "Yetkisiz." }, { status: 401 });
  }
  const supabase = createSupabaseAdminClient();
  if (!supabase) {
    return Response.json(
      { error: "Hatırlatma servisi yapılandırılmadı." },
      { status: 503 },
    );
  }
  try {
    const { data, error } = await supabase.rpc("process_reminders", {
      worker_now: new Date().toISOString(),
      batch_limit: 500,
    });
    if (error) throw error;
    const result = data as { created?: number } | null;
    console.info(
      JSON.stringify({
        event: "reminders.processed",
        created: result?.created ?? 0,
      }),
    );
    return Response.json(result ?? { created: 0 });
  } catch (error) {
    return apiError(error);
  }
}

export async function GET(request: Request) {
  return processReminders(request);
}

export async function POST(request: Request) {
  return processReminders(request);
}
