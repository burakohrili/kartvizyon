import { companyCreateSchema } from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";
import { assertQuota } from "@/lib/entitlements";
import { geocodeAddress } from "@/lib/geocoding";

export async function GET(request: Request) {
  const context = await getApiContext(request);
  if (!context.ok) return context.response;

  // Konum izni reddedilen kullanıcının belgelenen alternatifi arama ve manuel
  // adrestir (docs/STORE_RELEASE.md izin tablosu). Arama ve sayfalama birlikte
  // kullanılır; kayıt sayısı büyüdüğünde seçim listeleri eksik kalmaz.
  const params = new URL(request.url).searchParams;
  const query = params.get("q")?.trim();
  const requestedLimit = Number.parseInt(params.get("limit") ?? "50", 10);
  const requestedOffset = Number.parseInt(params.get("offset") ?? "0", 10);
  const limit = Number.isFinite(requestedLimit)
    ? Math.min(Math.max(requestedLimit, 1), 100)
    : 50;
  const offset = Number.isFinite(requestedOffset)
    ? Math.max(requestedOffset, 0)
    : 0;

  let builder = context.supabase
    .from("companies")
    .select(
      "id,name,display_name,phone,email,address,assigned_to,updated_at,latitude,longitude,location_source",
      { count: "exact" },
    )
    .eq("workspace_id", context.workspaceId)
    .is("archived_at", null);

  if (query) {
    // `%` ve `_` PostgREST desenini bozmasın diye kaçırılır.
    const escaped = query.replace(/[%_]/g, (char) => `\\${char}`);
    builder = builder.or(
      `name.ilike.%${escaped}%,display_name.ilike.%${escaped}%,address.ilike.%${escaped}%,email.ilike.%${escaped}%`,
    );
  }

  const { data, error, count } = await builder
    .order("updated_at", { ascending: false })
    .range(offset, offset + limit);
  if (error) return apiError(error);
  const rows = data ?? [];
  const hasMore = rows.length > limit;
  return Response.json({
    data: hasMore ? rows.slice(0, limit) : rows,
    page: {
      limit,
      offset,
      hasMore,
      nextOffset: hasMore ? offset + limit : null,
      total: count ?? offset + rows.length,
    },
  });
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
        display_name: input.displayName,
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
      .select(
        "id,name,display_name,created_at,latitude,longitude,location_source",
      )
      .single();
    if (error) return apiError(error);
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
