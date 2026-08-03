import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { OrderWorkbench } from "../operations-workbench";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
const demoCompanies = [
  { id: "00000000-0000-4000-8000-000000000101", name: "Atlas Medikal" },
];
const demoProducts = [
  {
    id: "00000000-0000-4000-8000-000000000401",
    name: "Endüstriyel Kontrol Ünitesi",
    list_price: 125000,
  },
];
const demoOrders = [
  {
    id: "00000000-0000-4000-8000-000000000501",
    status: "pending_approval",
    grand_total: 150000,
    currency: "TRY",
    company: { name: "Atlas Medikal" },
  },
];

export default async function OrdersPage() {
  const context = await getWebWorkspaceContext();
  const [orders, companies, products] = context
    ? await Promise.all([
        context.supabase
          .from("order_drafts")
          .select("*,company:companies(name)")
          .eq("workspace_id", context.workspaceId)
          .order("created_at", { ascending: false }),
        context.supabase
          .from("companies")
          .select("id,name")
          .eq("workspace_id", context.workspaceId)
          .is("archived_at", null)
          .order("name"),
        context.supabase
          .from("products")
          .select("id,name,list_price")
          .eq("workspace_id", context.workspaceId)
          .eq("active", true)
          .order("name"),
      ])
    : [{ data: demoOrders }, { data: demoCompanies }, { data: demoProducts }];
  return (
    <main className="customers-page">
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">KONTROLLÜ ÖN AKIŞ</span>
          <h1>Sipariş taslakları</h1>
          <p>ERP’ye dönüşmeden ürün, iskonto ve yönetici onayını yönetin.</p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          <strong>Demo görünümü.</strong> Kayıt işlemleri için Supabase
          bağlantısı gerekir.
        </div>
      )}
      <OrderWorkbench
        workspaceId={context?.workspaceId ?? demoWorkspace}
        initialItems={(orders.data ?? []) as Array<Record<string, unknown>>}
        companies={
          (companies.data ?? []) as Array<{ id: string; name: string }>
        }
        products={(products.data ?? []).map((product) => ({
          id: String(product.id),
          name: String(product.name),
          listPrice: Number(product.list_price),
        }))}
      />
    </main>
  );
}
