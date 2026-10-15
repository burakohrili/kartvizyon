import Link from "next/link";
import { TeamManager } from "./team-manager";
import { cookies } from "next/headers";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function TeamPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).workspaceAdmin;
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
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.companySettings}</span>
          <h1>{m.teamInvites}</h1>
          <p>{m.teamDescription}</p>
        </div>
        <Link className="secondary-action" href="/settings/organization">
          {m.teamsRegions}
        </Link>
      </header>
      <TeamManager
        organizationId={workspace?.organization_id ?? "demo-organization"}
        locale={locale}
      />
    </main>
  );
}
