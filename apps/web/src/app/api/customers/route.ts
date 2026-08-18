import { companyCreateSchema } from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";
import { assertQuota } from "@/lib/entitlements";
import { geocodeAddress } from "@/lib/geocoding";

export async function GET(request: Request) {
  const context = await getApiContext(request);
  if (!context.ok) return context.response;

  // Konum izni reddedilen kullanıcının belgelenen alternatifi arama ve manuel
  // adrestir (docs/STORE_RELEASE.md izin tablosu). Liste 100 kayıtla sınırlı
  // olduğu için arama olmadan bu alternatif fiilen çalışmıyordu.
  const query = new URL(request.url).searchParams.get("q")?.trim();

  let builder = context.supabase
    .from("companies")
    .select(
      "id,name,phone,email,address,assigned_to,updated_at,latitude,longitude,location_source",
    )
    .eq("workspace_id", context.workspaceId)
    .is("archived_at", null);

  if (query) {
    // `%` ve `_` PostgREST desenini bozmasın diye kaçırılır.
    const escaped = query.replace(/[%_]/g, (char) => `\${char}`);
    builder = builder.or(
      `name.ilike.%${escaped}%,address.ilike.%${escaped}%,email.ilike.%${escaped}%`,
    );
  }

  const { data, error } = await builder
    .order("updated_at", { ascending: false })
    .limit(100);
  if (error) return apiError(error);
  return Response.json({ data });
}

export async function POST(request: Request) {
  try {
    const input = companyCreateSchema.parse(await request.json());
    const context = await getApiContext(request);
    if (!context.ok) return context.response;

    // Çalışma alanı istek gövdesinden değil oturumdan gelir; gövdedeki değer
    // yalnız istemci tarafı kolaylığıdır ve yok sayılır.
    const quotaDenied = await assertQuota(context, "companies");
    if (quotaDenied) return quotaDenied;

    // Adresten tahmini koordinat. Başarısız olursa null döner ve kayıt yine
    // oluşur; müşteri kartındaki "konumu sabitle" akışı kesin değeri yazar.
    const coordinates = await geocodeAddress(input.address);

    const { data, error } = await context.supabase
      .from("companies")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        name: input.name,
        phone: input.phone,
        email: input.email,
        website: input.website,
        address: input.address,
        latitude: coordinates?.latitude ?? null,
        longitude: coordinates?.longitude ?? null,
        location_source: coordinates ? "geocoded" : null,
        location_updated_at: coordinates ? new Date().toISOString() : null,
        client_mutation_id: input.clientMutationId,
        created_by: context.user.id,
      })
      .select("id,name,created_at,latitude,longitude,location_source")
      .single();
    if (error) return apiError(error);
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
