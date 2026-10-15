import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { OrganizationStructure } from "./organization-structure";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function OrganizationPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).workspaceAdmin;
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
            ← {m.teamInvites}
          </Link>
          <span className="eyebrow">{m.teamEyebrow}</span>
          <h1>{m.organizationTitle}</h1>
          <p>{m.organizationDescription}</p>
        </div>
      </header>
      {context ? (
        <OrganizationStructure
          locale={locale}
          workspaceId={context.workspaceId}
          initialRegions={(regions.data ?? []) as Item[]}
          initialTeams={(teams.data ?? []) as Item[]}
        />
      ) : (
        <div className="demo-notice">{m.organizationDemo}</div>
      )}
    </main>
  );
}

type Item = Record<string, unknown>;
