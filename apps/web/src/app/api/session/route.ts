import { resolveEntitlement } from "@/lib/entitlements";
import { cookies } from "next/headers";
import { createSupabaseServerClient } from "@/lib/supabase/server";

/**
 * Supabase yanıt vermezse istek asılı kalmasın.
 *
 * Uç hiçbir yerde zaman aşımı uygulamıyordu; Supabase yavaşladığında işlev
 * platform tarafından kesiliyor ve istemciye **gövdesiz** bir 504 dönüyordu.
 * Okunacak bir `error` alanı olmadığı için testçinin ekranında "İşlem
 * tamamlanamadı. (HTTP 504)" yazıyordu. 19 Ağustos 2026'da böyle bir olay
 * Sentry'ye düştü (`/api/session`, Android, sürüm 1.0.0+42).
 *
 * Süre platformun kesme sınırının altında tutulur ki cevabı biz yazalım.
 */
const SUPABASE_TIMEOUT_MS = 6000;

class SessionTimeout extends Error {}

function withTimeout<T>(work: PromiseLike<T>): Promise<T> {
  return Promise.race([
    Promise.resolve(work),
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new SessionTimeout()), SUPABASE_TIMEOUT_MS),
    ),
  ]);
}

export async function GET(request: Request) {
  const supabase = await createSupabaseServerClient(request);
  if (!supabase)
    return Response.json({
      ownerId: "demo-local",
      workspaceId: "00000000-0000-4000-8000-000000000001",
      organizationId: null,
      displayName: null,
      workspaceCompanyName: null,
    });

  try {
    const { data } = await withTimeout(supabase.auth.getUser());
    if (!data.user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });

    const requestedWorkspaceId = request.headers.get("x-kartvizyon-workspace");
    let workspaceId =
      requestedWorkspaceId ??
      (await cookies()).get("kartvizyon_workspace")?.value ??
      null;
    let workspace: {
      id: string;
      name: string;
      kind: string;
      organization_id: string | null;
    } | null = null;
    if (workspaceId && !workspaceId.startsWith("demo-")) {
      const selected = await withTimeout(
        supabase
          .from("workspaces")
          .select("id,name,kind,organization_id")
          .eq("id", workspaceId)
          .maybeSingle(),
      );
      workspace = selected.data;
      if (
        requestedWorkspaceId &&
        requestedWorkspaceId !== "00000000-0000-4000-8000-000000000001" &&
        !workspace
      )
        return Response.json(
          { error: "Çalışma alanına erişiminiz yok." },
          { status: 403 },
        );
    }
    if (!workspace) {
      const first = await withTimeout(
        supabase
          .from("workspaces")
          .select("id,name,kind,organization_id")
          .limit(1)
          .maybeSingle(),
      );
      workspace = first.data;
    }
    const profile = await withTimeout(
      supabase
        .from("profiles")
        .select("full_name,timezone")
        .eq("id", data.user.id)
        .maybeSingle(),
    );
    if (profile.error) throw profile.error;
    const storedName = profile.data?.full_name?.trim() ?? "";
    const emailLocalPart = data.user.email?.split("@")[0]?.toLowerCase();
    const displayName =
      storedName && storedName.toLowerCase() !== emailLocalPart
        ? storedName
        : null;
    const organization = workspace?.organization_id
      ? await withTimeout(
          supabase
            .from("organizations")
            .select("name")
            .eq("id", workspace.organization_id)
            .maybeSingle(),
        )
      : null;
    if (organization?.error) throw organization.error;
    const canonicalName = organization?.data?.name ?? workspace?.name;
    const workspaceCompanyName =
      canonicalName === "Kişisel Alanım" ? null : (canonicalName ?? null);
    return Response.json({
      ownerId: data.user.id,
      workspaceId: workspace?.id ?? null,
      organizationId: workspace?.organization_id ?? null,
      workspaceKind: workspace?.kind ?? null,
      displayName,
      timezone: profile.data?.timezone ?? "UTC",
      workspaceCompanyName,
      entitlement: workspace
        ? await withTimeout(resolveEntitlement(supabase, workspace.id))
        : null,
    });
  } catch (error) {
    if (error instanceof SessionTimeout) {
      // Kullanıcıya ne olduğunu ve ne yapacağını söyleyen bir gövde; 503
      // istemci tarafında "tekrar dene" davranışına karşılık gelir.
      return Response.json(
        {
          error:
            "Sunucuya şu an ulaşılamıyor. Birkaç saniye sonra tekrar deneyin.",
        },
        { status: 503 },
      );
    }
    throw error;
  }
}
