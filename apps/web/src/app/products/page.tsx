import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { PriceListWorkbench, ProductWorkbench } from "../operations-workbench";
import { DemoBanner } from "@/app/demo-banner";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
const demoItems = [
  {
    id: "00000000-0000-4000-8000-000000000401",
    sku: "KV-100",
    name: "Endüstriyel Kontrol Ünitesi",
    unit: "adet",
    tax_rate: 20,
    list_price: 125000,
    currency: "TRY",
  },
];

export default async function ProductsPage() {
  const context = await getWebWorkspaceContext();
  const [products, priceLists] = context
    ? await Promise.all([
        context.supabase
          .from("products")
          .select("*")
          .eq("workspace_id", context.workspaceId)
          .eq("active", true)
          .order("name"),
        context.supabase
          .from("documents")
          .select("id,file_name,scan_status,created_at")
          .eq("workspace_id", context.workspaceId)
          .eq("purpose", "price_list")
          .order("created_at", { ascending: false }),
      ])
    : [{ data: demoItems }, { data: [] }];
  return (
    <main className="customers-page">
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">ÜRÜN VE FİYAT</span>
          <h1>Ürün kataloğu</h1>
          <p>
            Sipariş taslaklarında kullanılacak kontrollü ürün ve liste
            fiyatları.
          </p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          <strong>Demo görünümü.</strong> Kayıt işlemleri için Supabase
          bağlantısı gerekir.
        </div>
      )}
      <ProductWorkbench
        workspaceId={context?.workspaceId ?? demoWorkspace}
        initialItems={(products.data ?? []) as Array<Record<string, unknown>>}
      />
      <h2 className="section-title">Fiyat listeleri</h2>
      <p>
        Saha ekibi bu listeleri mobil uygulamada salt okunur görür ve açar;
        yükleme yalnız buradan yapılır.
      </p>
      <PriceListWorkbench
        initialItems={(priceLists.data ?? []) as Array<Record<string, unknown>>}
      />
    </main>
  );
}
