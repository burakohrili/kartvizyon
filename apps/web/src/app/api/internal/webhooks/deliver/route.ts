import { createHmac } from "node:crypto";
import { hasInternalSecret } from "@/lib/internal-auth";
import { assertPublicHttpsUrl } from "@/lib/public-url";
import { decryptSecret } from "@/lib/secret-box";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

type Endpoint = {
  url: string;
  active: boolean;
  signing_secret_ciphertext: string;
};

export async function POST(request: Request) {
  if (
    !hasInternalSecret(request, "WEBHOOK_WORKER_SECRET") &&
    !hasInternalSecret(request, "CRON_SECRET")
  )
    return Response.json({ error: "Yetkisiz." }, { status: 401 });
  const supabase = createSupabaseAdminClient();
  if (!supabase)
    return Response.json(
      { error: "Supabase admin bağlantısı yok." },
      { status: 503 },
    );

  const due = await supabase
    .from("webhook_deliveries")
    .select(
      "id,event_type,event_id,payload,attempt,endpoint:webhook_endpoints(url,active,signing_secret_ciphertext)",
    )
    .is("delivered_at", null)
    .lte("next_attempt_at", new Date().toISOString())
    .order("created_at")
    .limit(50);
  if (due.error)
    return Response.json({ error: due.error.message }, { status: 500 });

  let delivered = 0;
  let failed = 0;
  for (const item of due.data ?? []) {
    const endpointValue = item.endpoint as unknown;
    const endpoint = (
      Array.isArray(endpointValue) ? endpointValue[0] : endpointValue
    ) as Endpoint | null;
    if (!endpoint?.active) continue;
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const body = JSON.stringify(item.payload);
    try {
      const url = await assertPublicHttpsUrl(endpoint.url);
      const secret = decryptSecret(endpoint.signing_secret_ciphertext);
      const signature = createHmac("sha256", secret)
        .update(`${timestamp}.${body}`)
        .digest("hex");
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "user-agent": "KartVizyon-Webhook/1.0",
          "x-kartvizyon-event": item.event_type,
          "x-kartvizyon-delivery": item.event_id,
          "x-kartvizyon-timestamp": timestamp,
          "x-kartvizyon-signature": `sha256=${signature}`,
        },
        body,
        redirect: "error",
        signal: AbortSignal.timeout(10_000),
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      await supabase
        .from("webhook_deliveries")
        .update({
          response_status: response.status,
          delivered_at: new Date().toISOString(),
          error_message: null,
          next_attempt_at: null,
        })
        .eq("id", item.id);
      delivered += 1;
    } catch (error) {
      const attempt = Number(item.attempt) + 1;
      const retryMinutes = Math.min(2 ** attempt, 24 * 60);
      await supabase
        .from("webhook_deliveries")
        .update({
          attempt,
          error_message:
            error instanceof Error
              ? error.message.slice(0, 500)
              : "Teslimat hatası",
          next_attempt_at:
            attempt >= 10
              ? null
              : new Date(Date.now() + retryMinutes * 60_000).toISOString(),
        })
        .eq("id", item.id);
      failed += 1;
    }
  }
  return Response.json({
    processed: (due.data ?? []).length,
    delivered,
    failed,
  });
}

export const GET = POST;
