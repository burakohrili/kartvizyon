import Link from "next/link";
import { ImportWizard } from "./wizard";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { DemoBanner } from "@/app/demo-banner";

export default async function ImportPage() {
  const supabase = await createSupabaseServerClient();
  const { data: workspace } = supabase
    ? await supabase
        .from("workspaces")
        .select("id,organization_id")
        .limit(1)
        .maybeSingle()
    : { data: null };
  return (
    <main className="customers-page">
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/customers" className="back-link">
            ← Müşteriler
          </Link>
          <span className="eyebrow">VERİ İÇE AKTARMA</span>
          <h1>Excel veya CSV’den müşteri ekle</h1>
          <p>
            Kolonları kontrol edin; hatalı satırlar ve benzer kayıtlar içe
            aktarmadan önce gösterilir.
          </p>
        </div>
      </header>
      <ImportWizard
        workspaceId={workspace?.id ?? "00000000-0000-4000-8000-000000000001"}
        organizationId={workspace?.organization_id ?? null}
      />
    </main>
  );
}
