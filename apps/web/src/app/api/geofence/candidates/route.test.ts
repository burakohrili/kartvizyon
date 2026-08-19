import { beforeEach, describe, expect, it, vi } from "vitest";

/**
 * Uzaktaki tek bir müşteri, yakındakileri bulmayı bozmamalı.
 *
 * Puanlama girdisi `distanceKm <= 500` ile doğrulanıyor ve yarıçap filtresi
 * puanlamadan SONRA çalışıyordu. Çalışma alanında 500 km'den uzak bir müşteri
 * bulunması, o kullanıcı için ucun tamamen 500 dönmesine yetiyordu; saha modu
 * ve harita birlikte çalışmıyordu (Sentry, iOS 46 ve Android 40).
 */

type Row = Record<string, unknown>;
const tables = new Map<string, Row[]>();

function query(table: string) {
  const builder: Record<string, unknown> = {};
  for (const method of [
    "select",
    "eq",
    "not",
    "is",
    "limit",
    "order",
    "lt",
    "gte",
  ])
    builder[method] = () => builder;
  builder.then = (resolve: (value: unknown) => unknown) =>
    Promise.resolve({ data: tables.get(table) ?? [], error: null }).then(
      resolve,
    );
  return builder;
}

vi.mock("@/lib/supabase/server", () => ({
  createSupabaseServerClient: async () => ({
    auth: { getUser: async () => ({ data: { user: { id: "user-1" } } }) },
    from: (table: string) => query(table),
  }),
}));

const { GET } = await import("./route");

// İzmir Bornova çevresi.
const here = { latitude: 38.46, longitude: 27.21 };

function request(radius?: number) {
  const params = new URLSearchParams({
    workspaceId: "11111111-1111-4111-8111-111111111111",
    latitude: String(here.latitude),
    longitude: String(here.longitude),
  });
  if (radius) params.set("maxDistanceKm", String(radius));
  return new Request(
    `https://app.kartvizyon.app/api/geofence/candidates?${params}`,
  );
}

beforeEach(() => {
  tables.clear();
  tables.set("visits", []);
  tables.set("tasks", []);
  tables.set("geofence_events", []);
});

describe("yakındaki müşteri adayları", () => {
  it("çok uzaktaki müşteri ucu çökertmez", async () => {
    tables.set("companies", [
      { id: "yakin", name: "Atlas Medikal", latitude: 38.47, longitude: 27.22 },
      // Londra: ~2900 km. Puanlama şeması 500 km'yi aşan mesafeyi reddediyor.
      {
        id: "uzak",
        name: "Yanlış Koordinat",
        latitude: 51.5,
        longitude: -0.12,
      },
      // Geocoding başarısız olup sıfır yazarsa oluşan klasik hatalı koordinat.
      { id: "sifir", name: "Sıfır Nokta", latitude: 0, longitude: 0 },
    ]);

    const response = await GET(request());

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.data.map((row: Row) => row.id)).toEqual(["yakin"]);
  });

  it("ileri tarihli onay negatif gün üretip şemayı kırmaz", async () => {
    const tomorrow = new Date(Date.now() + 86_400_000).toISOString();
    tables.set("companies", [
      { id: "yakin", name: "Atlas Medikal", latitude: 38.47, longitude: 27.22 },
    ]);
    tables.set("visits", [{ company_id: "yakin", approved_at: tomorrow }]);

    const response = await GET(request());

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.data[0].daysSinceVisit).toBe(0);
  });

  it("saha modunun dar yarıçapına uyar", async () => {
    tables.set("companies", [
      {
        id: "cok-yakin",
        name: "Yan Sokak",
        latitude: 38.462,
        longitude: 27.212,
      },
      { id: "on-km", name: "On Km", latitude: 38.55, longitude: 27.21 },
    ]);

    const response = await GET(request(1.5));

    const body = await response.json();
    expect(body.data.map((row: Row) => row.id)).toEqual(["cok-yakin"]);
    expect(body.maxDistanceKm).toBe(1.5);
  });

  it("geçersiz konum 400 döner", async () => {
    const response = await GET(
      new Request(
        "https://app.kartvizyon.app/api/geofence/candidates?workspaceId=x&latitude=200&longitude=0",
      ),
    );
    expect(response.status).toBe(400);
  });
});
