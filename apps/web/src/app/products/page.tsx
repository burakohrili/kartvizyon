import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { PriceListWorkbench, ProductWorkbench } from "../operations-workbench";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";
import { getDemoRecords } from "@/lib/i18n/demo-records";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
export default async function ProductsPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).operations;
  const demo = getDemoRecords(locale);
  const demoItems = [
    {
      id: "00000000-0000-4000-8000-000000000401",
      sku: "KV-100",
      name: demo.product,
      unit: locale === "en" ? "unit" : "adet",
      tax_rate: 20,
      list_price: 125000,
      currency: "TRY",
    },
  ];
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
            {m.back}
          </Link>
          <span className="eyebrow">{m.productsEyebrow}</span>
          <h1>{m.productsTitle}</h1>
          <p>{m.productsDescription}</p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          <strong>{m.demoTitle}</strong> {m.demoBody}
        </div>
      )}
      <ProductWorkbench
        locale={locale}
        workspaceId={context?.workspaceId ?? demoWorkspace}
        initialItems={(products.data ?? []) as Array<Record<string, unknown>>}
      />
      <h2 className="section-title">{m.priceListsTitle}</h2>
      <p>{m.priceListsDescription}</p>
      <PriceListWorkbench
        locale={locale}
        initialItems={(priceLists.data ?? []) as Array<Record<string, unknown>>}
      />
    </main>
  );
}
