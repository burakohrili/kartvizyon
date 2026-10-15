import Link from "next/link";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";
import { formatDateTime } from "@/lib/i18n/locale";
import { getDemoRecords } from "@/lib/i18n/demo-records";

type Visit = {
  id: string;
  status: string;
  purpose: string | null;
  completed_at: string | null;
  company: { name: string } | null;
};
async function getVisits(
  locale: "en" | "tr",
): Promise<{ visits: Visit[]; demo: boolean }> {
  const demo = getDemoRecords(locale);
  const demos: Visit[] = [
    {
      id: "demo-review",
      status: "needs_review",
      purpose: demo.visitPurposes[0],
      completed_at: "2026-08-02T10:42:00Z",
      company: { name: demo.companies[0] },
    },
    {
      id: "demo-approved",
      status: "approved",
      purpose: demo.visitPurposes[1],
      completed_at: "2026-08-01T15:10:00Z",
      company: { name: demo.companies[1] },
    },
    {
      id: "demo-draft",
      status: "draft",
      purpose: demo.visitPurposes[2],
      completed_at: null,
      company: { name: demo.companies[2] },
    },
  ];
  const supabase = await createSupabaseServerClient();
  if (!supabase) return { visits: demos, demo: true };
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { visits: demos, demo: true };
  const { data: workspace } = await supabase
    .from("workspaces")
    .select("id")
    .limit(1)
    .single();
  if (!workspace) return { visits: [], demo: false };
  const { data } = await supabase
    .from("visits")
    .select("id,status,purpose,completed_at,company:companies(name)")
    .eq("workspace_id", workspace.id)
    .order("created_at", { ascending: false });
  return { visits: (data as unknown as Visit[] | null) ?? [], demo: false };
}

export default async function VisitsPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).visits;
  const { visits, demo: isDemo } = await getVisits(locale);
  const labels: Record<string, string> = {
    draft: m.draftStatus,
    processing: m.processingStatus,
    needs_review: m.needsReviewStatus,
    approved: m.approvedStatus,
    rejected: m.rejectedStatus,
    archived: m.archivedStatus,
  };
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
        <Link href="/visits/demo-draft/debrief" className="primary">
          {m.add}
        </Link>
      </header>
      {isDemo && (
        <div className="demo-notice">
          <strong>{m.demoTitle}</strong> {m.demoBody}
        </div>
      )}
      <section className="visit-summary-row">
        <article>
          <small>{m.awaitingReview}</small>
          <strong>
            {visits.filter((v) => v.status === "needs_review").length}
          </strong>
        </article>
        <article>
          <small>{m.approved}</small>
          <strong>
            {visits.filter((v) => v.status === "approved").length}
          </strong>
        </article>
        <article>
          <small>{m.drafts}</small>
          <strong>{visits.filter((v) => v.status === "draft").length}</strong>
        </article>
      </section>
      <section className="visit-list">
        {visits.map((visit) => (
          <article key={visit.id}>
            <span className={`status-dot ${visit.status}`} />
            <div>
              <strong>{visit.company?.name ?? m.companyMissing}</strong>
              <p>{visit.purpose ?? m.purposeMissing}</p>
              <small>
                {visit.completed_at
                  ? formatDateTime(visit.completed_at, locale)
                  : m.notCompleted}
              </small>
            </div>
            <span className={`status-pill ${visit.status}`}>
              {labels[visit.status] ?? m.unknownStatus}
            </span>
            {visit.status === "needs_review" ? (
              <Link href={`/visits/${visit.id}/review`}>{m.review}</Link>
            ) : visit.status === "draft" ? (
              <Link href={`/visits/${visit.id}/debrief`}>{m.addNote}</Link>
            ) : (
              <button aria-label={m.menu}>•••</button>
            )}
          </article>
        ))}
      </section>
    </main>
  );
}
