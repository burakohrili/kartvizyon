import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";
import { assertQuota } from "@/lib/entitlements";
import {
  businessCardLimits,
  businessCardModel,
  detectBusinessCardMimeType,
  extractBusinessCard,
} from "@/lib/openai/business-card";
import { getSupabaseConfig } from "@/lib/supabase/config";

export const runtime = "nodejs";

export async function POST(request: Request) {
  try {
    // Supabase yapılandırılmamış yerel/demo kurulumda OCR denenebilir kalır;
    // production'da oturum, kota ve ölçüm zorunludur.
    const configured = getSupabaseConfig() !== null;
    const context = configured ? await getApiContext(request) : null;
    if (context && !context.ok) return context.response;

    if (context?.ok) {
      const quotaDenied = await assertQuota(context, "ocr");
      if (quotaDenied) return quotaDenied;
    }

    const form = await request.formData();
    const image = form.get("image");
    if (!(image instanceof File) || image.size === 0) {
      return Response.json(
        { error: "Kartvizit görseli gerekli." },
        { status: 400 },
      );
    }
    if (image.size > businessCardLimits.maxBytes) {
      return Response.json(
        { error: "Görsel en fazla 10 MB olabilir." },
        { status: 413 },
      );
    }
    const bytes = new Uint8Array(await image.arrayBuffer());
    const detectedType = detectBusinessCardMimeType(bytes);
    if (!detectedType) {
      return Response.json(
        { error: "Yalnızca JPEG, PNG veya WebP yükleyin." },
        { status: 415 },
      );
    }

    const encoded = Buffer.from(bytes).toString("base64");
    const extraction = await extractBusinessCard(
      `data:${detectedType};base64,${encoded}`,
    );

    if (context?.ok) {
      // Kota sayacı yalnız başarılı tarama için ilerler.
      await context.supabase.from("usage_records").insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        user_id: context.user.id,
        metric: "ocr",
        quantity: 1,
        unit: "card",
        provider: "openai",
        model: businessCardModel,
      });
    }

    return Response.json({ data: extraction });
  } catch (error) {
    const openAiError = error as { status?: number; code?: string };
    if (
      openAiError.status === 429 ||
      openAiError.code === "credit_balance_exhausted"
    ) {
      console.error(error);
      return Response.json(
        {
          error:
            "Kartvizit tarama servisi kullanım limitine ulaştı. Lütfen daha sonra tekrar deneyin veya müşteriyi manuel ekleyin.",
        },
        { status: 503 },
      );
    }
    return apiError(error);
  }
}
