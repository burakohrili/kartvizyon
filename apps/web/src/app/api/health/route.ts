import { getSupabaseConfig } from "@/lib/supabase/config";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

/**
 * Kodun beklediği ama migration uygulanmadığında var olmayan kolonlar.
 *
 * 18 Ağustos 2026'da müşteri uçları production'da 500 döndü çünkü kod
 * `companies.location_source` kolonunu seçiyordu ve `0022` uygulanmamıştı.
 * Hata yalnız test kullanıcısının ekranında "İşlem tamamlanamadı." olarak
 * göründü; hangi migration'ın eksik olduğu hiçbir yerden anlaşılmıyordu.
 */
const REQUIRED_COLUMNS: { table: string; column: string; migration: string }[] =
  [
    {
      table: "subscription_plans",
      column: "max_companies",
      migration: "0021_entitlements",
    },
    {
      table: "companies",
      column: "location_source",
      migration: "0022_company_location_source",
    },
  ];

async function findSchemaDrift(): Promise<string[]> {
  const supabase = createSupabaseAdminClient();
  if (!supabase) return [];

  const missing: string[] = [];
  await Promise.all(
    REQUIRED_COLUMNS.map(async ({ table, column, migration }) => {
      // Kolon yoksa PostgREST 42703 döner; satır sayısı önemli değil.
      const { error } = await supabase.from(table).select(column).limit(1);
      if (error) missing.push(`${table}.${column} (${migration})`);
    }),
  );
  return missing;
}

export async function GET() {
  const databaseConfigured = getSupabaseConfig() !== null;
  const pendingMigrations = databaseConfigured ? await findSchemaDrift() : [];

  return Response.json(
    {
      status: pendingMigrations.length ? "degraded" : "ok",
      service: "kartvizyon-web",
      version: process.env.npm_package_version ?? "0.1.0",
      uptimeSeconds: Math.round(process.uptime()),
      databaseConfigured,
      aiConfigured: Boolean(process.env.OPENAI_API_KEY),
      adminConfigured: Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),
      geocodingConfigured: Boolean(process.env.GOOGLE_GEOCODING_API_KEY),
      // Boş değilse uygulama çalışıyor gibi görünür ama ilgili ekranlar
      // 500 döner; önce bu migration'lar uygulanmalıdır.
      pendingMigrations,
      timestamp: new Date().toISOString(),
    },
    { status: 200 },
  );
}
