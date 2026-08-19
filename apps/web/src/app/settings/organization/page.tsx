import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { OrganizationStructure } from "./organization-structure";
import { DemoBanner } from "@/app/demo-banner";

export default async function OrganizationPage() {
  const context = await getWebWorkspaceContext();
  const [regions, teams] = context
    ? await Promise.all([
        context.supabase
          .from("regions")
          .select("*")
          .eq("workspace_id", context.workspaceId)
          .is("archived_at", null)
          .order("name"),
        context.supabase
          .from("teams")
          .select("*,region:regions(name)")
          .eq("workspace_id", context.workspaceId)
          .is("archived_at", null)
          .order("name"),
      ])
    : [{ data: [] }, { data: [] }];
  return (
    <main className="customers-page">
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/settings/team" className="back-link">
            ← Ekip ve davetler
          </Link>
          <span className="eyebrow">EKİP VE BÖLGE</span>
          <h1>Organizasyon yapısı</h1>
          <p>Takımları ve bölgeleri şirket çalışma alanında yönetin.</p>
        </div>
      </header>
      {context ? (
        <OrganizationStructure
          workspaceId={context.workspaceId}
          initialRegions={(regions.data ?? []) as Item[]}
          initialTeams={(teams.data ?? []) as Item[]}
        />
      ) : (
        <div className="demo-notice">
          Bu ekran için şirket Supabase oturumu gerekir.
        </div>
      )}
    </main>
  );
}

type Item = Record<string, unknown>;
