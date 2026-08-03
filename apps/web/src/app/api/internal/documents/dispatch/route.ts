import { hasInternalSecret } from "@/lib/internal-auth";

export const runtime = "nodejs";
export const maxDuration = 60;

export async function POST(request: Request) {
  if (!hasInternalSecret(request, "CRON_SECRET"))
    return Response.json({ error: "Yetkisiz." }, { status: 401 });

  const serviceUrl = process.env.DOCUMENT_SCAN_SERVICE_URL;
  const scanSecret = process.env.DOCUMENT_SCAN_SECRET;
  if (!serviceUrl || !scanSecret)
    return Response.json(
      { error: "Belge tarama servisi yapılandırılmamış." },
      { status: 503 },
    );

  try {
    const response = await fetch(new URL("/scan", serviceUrl), {
      method: "POST",
      headers: {
        authorization: `Bearer ${scanSecret}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ limit: 5 }),
      signal: AbortSignal.timeout(55_000),
    });
    const result = await response.json().catch(() => null);
    if (!response.ok)
      throw new Error(
        typeof result?.error === "string"
          ? result.error
          : `Tarayıcı HTTP ${response.status}`,
      );
    return Response.json(result);
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        event: "document.scan_dispatch_failed",
        error: error instanceof Error ? error.message : "unknown",
      }),
    );
    return Response.json(
      { error: "Tarama servisine ulaşılamadı." },
      { status: 502 },
    );
  }
}

export const GET = POST;
