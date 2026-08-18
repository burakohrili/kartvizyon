import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

/**
 * Müşterinin konumunu sahada sabitler.
 *
 * Saha çalışanı müşterinin kapısındayken cihazın konumunu müşteri kaydına
 * yazar. Adresten tahmin edilen koordinattan daha güvenilir olduğu için
 * `location_source = 'pinned'` her zaman `geocoded`'i ezer.
 *
 * Kaydedilen şey müşterinin konumudur; kullanıcının hareket geçmişi
 * tutulmaz (bkz. CLAUDE.md — sürekli GPS takibi yapılmaz).
 */
const pinSchema = z.object({
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
});

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    if (!z.uuid().safeParse(id).success) {
      return Response.json(
        { error: "Müşteri kimliği geçersiz." },
        { status: 400 },
      );
    }

    const input = pinSchema.parse(await request.json());
    const context = await getApiContext(request);
    if (!context.ok) return context.response;

    // Çalışma alanı oturumdan gelir; RLS ayrıca kiracı sınırını uygular.
    const { data, error } = await context.supabase
      .from("companies")
      .update({
        latitude: input.latitude,
        longitude: input.longitude,
        location_source: "pinned",
        location_updated_at: new Date().toISOString(),
      })
      .eq("id", id)
      .eq("workspace_id", context.workspaceId)
      .select("id,name,latitude,longitude,location_source")
      .maybeSingle();
    if (error) return apiError(error);
    if (!data) {
      return Response.json(
        { error: "Müşteri bulunamadı veya erişiminiz yok." },
        { status: 404 },
      );
    }

    await context.supabase.from("audit_logs").insert({
      organization_id: context.organizationId,
      workspace_id: context.workspaceId,
      actor_id: context.user.id,
      action: "company.location_pinned",
      resource_type: "company",
      resource_id: id,
    });

    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}
