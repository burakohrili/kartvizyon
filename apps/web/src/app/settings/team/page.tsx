import Link from "next/link";
import { TeamManager } from "./team-manager";
import { cookies } from "next/headers";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export default async function TeamPage() {
  const workspaceId = (await cookies()).get("kartvizyon_workspace")?.value;
  const supabase = await createSupabaseServerClient();
  const { data: workspace } =
    supabase && workspaceId
      ? await supabase
          .from("workspaces")
          .select("organization_id")
          .eq("id", workspaceId)
          .maybeSingle()
      : { data: null };
  return (
    <main className="customers-page">
      <header className="customers-header">
        <div>
          <Link href="/" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">ŞİRKET AYARLARI</span>
          <h1>Ekip ve davetler</h1>
          <p>
            Kullanıcıları yalnızca ihtiyaç duydukları rol ve verilerle çalışma
            alanına davet edin.
          </p>
        </div>
        <Link className="secondary-action" href="/settings/organization">
          Takım ve bölgeler
        </Link>
      </header>
      <TeamManager
        organizationId={workspace?.organization_id ?? "demo-organization"}
      />
    </main>
  );
}
