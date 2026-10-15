import Link from "next/link";
import { ImportWizard } from "./wizard";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { DemoBanner } from "@/app/demo-banner";
import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export default async function ImportPage() {
  const locale = await getRequestLocale();
  const messages = getMessages(locale).import;
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
            {messages.back}
          </Link>
          <span className="eyebrow">{messages.eyebrow}</span>
          <h1>{messages.title}</h1>
          <p>{messages.description}</p>
        </div>
      </header>
      <ImportWizard
        workspaceId={workspace?.id ?? "00000000-0000-4000-8000-000000000001"}
        organizationId={workspace?.organization_id ?? null}
        locale={locale}
      />
    </main>
  );
}
