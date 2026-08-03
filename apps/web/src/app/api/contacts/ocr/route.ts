import { apiError } from "@/lib/api";
import {
  businessCardLimits,
  extractBusinessCard,
} from "@/lib/openai/business-card";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

export async function POST(request: Request) {
  try {
    const supabase = await createSupabaseServerClient(request);
    if (supabase) {
      const { data } = await supabase.auth.getUser();
      if (!data.user)
        return Response.json({ error: "Oturum gerekli." }, { status: 401 });
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
    if (!businessCardLimits.acceptedTypes.has(image.type)) {
      return Response.json(
        { error: "Yalnızca JPEG, PNG veya WebP yükleyin." },
        { status: 415 },
      );
    }

    const encoded = Buffer.from(await image.arrayBuffer()).toString("base64");
    const extraction = await extractBusinessCard(
      `data:${image.type};base64,${encoded}`,
    );
    return Response.json({ data: extraction });
  } catch (error) {
    return apiError(error);
  }
}
