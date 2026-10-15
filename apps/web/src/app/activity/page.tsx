import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { ActivityFeed } from "../interaction-workbench";
import { DemoBanner } from "@/app/demo-banner";
import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getDemoRecords } from "@/lib/i18n/demo-records";

function demoVisitsFor(locale: "en" | "tr") {
  const demo = getDemoRecords(locale);
  return [
    {
      id: "00000000-0000-4000-8000-000000000701",
      approved_at: new Date().toISOString(),
      company: { name: demo.companies[0] },
      representative: { full_name: demo.representative },
      ai_summary: {
        summary: demo.activitySummary,
      },
    },
  ];
}

export default async function ActivityPage() {
  const [context, locale] = await Promise.all([
    getWebWorkspaceContext(),
    getRequestLocale(),
  ]);
  const m = getMessages(locale).activity;
  const demoVisits = demoVisitsFor(locale);
  const [visits, comments] = context
    ? await Promise.all([
        context.supabase
          .from("visits")
          .select(
            "id,approved_at,ai_summary,company:companies(name),representative:profiles(full_name)",
          )
          .eq("workspace_id", context.workspaceId)
          .eq("status", "approved")
          .order("approved_at", { ascending: false })
          .limit(100),
        context.supabase
          .from("activity_comments")
          .select("*,author:profiles(full_name)")
          .eq("workspace_id", context.workspaceId)
          .is("deleted_at", null)
          .order("created_at"),
      ])
    : [{ data: demoVisits }, { data: [] }];
  return (
    <main className="customers-page">
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.eyebrow}</span>
          <h1>{m.title}</h1>
          <p>{m.description}</p>
        </div>
      </header>
      {!context && <div className="demo-notice">{m.demo}</div>}
      <ActivityFeed
        initialVisits={(visits.data ?? []) as Item[]}
        initialComments={(comments.data ?? []) as Item[]}
        locale={locale}
      />
    </main>
  );
}
type Item = Record<string, unknown>;
