import { cookies } from "next/headers";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function getApiContext(request: Request) {
  const supabase = await createSupabaseServerClient(request);
  if (!supabase) {
    return {
      ok: false as const,
      response: Response.json(
        { error: "Supabase bağlantısı henüz yapılandırılmadı." },
        { status: 503 },
      ),
    };
  }
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return {
      ok: false as const,
      response: Response.json({ error: "Oturum gerekli." }, { status: 401 }),
    };
  }
  const routeKey = new URL(request.url).pathname;
  const { data: allowed, error: limitError } = await supabase.rpc(
    "consume_api_rate_limit",
    { route_key: routeKey, request_limit: 120, window_seconds: 60 },
  );
  if (!limitError && allowed === false) {
    return {
      ok: false as const,
      response: Response.json(
        { error: "Çok fazla istek. Kısa süre sonra yeniden deneyin." },
        { status: 429, headers: { "Retry-After": "60" } },
      ),
    };
  }
  // Çalışma alanı kimliği önce istemciden okunur.
  //
  // Mobil istemci çerez göndermiyor ve uçların çoğuna `workspaceId` de
  // eklemiyordu; bu yüzden aşağıdaki "ilk çalışma alanı" geri düşüşü devreye
  // giriyor ve birden fazla çalışma alanı olan kullanıcı yanlış alanın
  // verisini görüyordu. İstemciden gelen kimliği kabul etmek yetki açmaz:
  // aşağıdaki `.eq("id", workspaceId).single()` sorgusu kullanıcı kapsamlı
  // istemciyle ve RLS altında çalışır, erişimi olmayan alan 403 döner.
  let workspaceId =
    request.headers.get("x-kartvizyon-workspace") ??
    new URL(request.url).searchParams.get("workspaceId") ??
    (await cookies()).get("kartvizyon_workspace")?.value ??
    null;
  if (!workspaceId || workspaceId.startsWith("demo-")) {
    const first = await supabase
      .from("workspaces")
      .select("id,organization_id")
      .limit(1)
      .single();
    workspaceId = first.data?.id ?? null;
  }
  if (!workspaceId) {
    return {
      ok: false as const,
      response: Response.json(
        { error: "Aktif çalışma alanı bulunamadı." },
        { status: 409 },
      ),
    };
  }
  const workspace = await supabase
    .from("workspaces")
    .select("id,organization_id")
    .eq("id", workspaceId)
    .single();
  if (!workspace.data) {
    return {
      ok: false as const,
      response: Response.json(
        { error: "Çalışma alanına erişiminiz yok." },
        { status: 403 },
      ),
    };
  }
  return {
    ok: true as const,
    supabase,
    user,
    workspaceId,
    organizationId: workspace.data.organization_id as string | null,
  };
}
