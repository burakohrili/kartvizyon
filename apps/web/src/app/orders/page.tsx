import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { OrderWorkbench } from "../operations-workbench";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";
import { getDemoRecords } from "@/lib/i18n/demo-records";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
export default async function OrdersPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).operations;
  const demo = getDemoRecords(locale);
  const demoCompanies = [
    { id: "00000000-0000-4000-8000-000000000101", name: demo.companies[0] },
  ];
  const demoProducts = [
    {
      id: "00000000-0000-4000-8000-000000000401",
      name: demo.product,
      list_price: 125000,
    },
  ];
  const demoOrders = [
    {
      id: "00000000-0000-4000-8000-000000000501",
      status: "pending_approval",
      grand_total: 150000,
      currency: "TRY",
      company: { name: demo.companies[0] },
    },
  ];
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
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.ordersEyebrow}</span>
          <h1>{m.ordersTitle}</h1>
          <p>{m.ordersDescription}</p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          <strong>{m.demoTitle}</strong> {m.demoBody}
        </div>
      )}
      <OrderWorkbench
        locale={locale}
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
