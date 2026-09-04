import { createClient } from "@supabase/supabase-js";
import { audioBucketName } from "@/lib/storage-config";

export const runtime = "nodejs";

function authorized(request: Request) {
  const secret = process.env.CRON_SECRET;
  return Boolean(
    secret && request.headers.get("authorization") === `Bearer ${secret}`,
  );
}

export async function POST(request: Request) {
  if (!authorized(request)) {
    return Response.json({ error: "Yetkisiz." }, { status: 401 });
  }
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !serviceKey) {
    return Response.json(
      { error: "Retention servisi yapılandırılmadı." },
      { status: 503 },
    );
  }

  const supabase = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const expired = await supabase
    .from("visit_audio_assets")
    .select("id,storage_path")
    .is("deleted_at", null)
    .lte("delete_after", new Date().toISOString())
    .limit(100);
  if (expired.error) throw expired.error;
  if (!expired.data.length) return Response.json({ deleted: 0 });

  const paths = expired.data.map((asset) => asset.storage_path);
  const removal = await supabase.storage.from(audioBucketName()).remove(paths);
  if (removal.error) throw removal.error;

  const ids = expired.data.map((asset) => asset.id);
  const updated = await supabase
    .from("visit_audio_assets")
    .update({ deleted_at: new Date().toISOString() })
    .in("id", ids);
  if (updated.error) throw updated.error;

  return Response.json({ deleted: ids.length });
}

export const GET = POST;
