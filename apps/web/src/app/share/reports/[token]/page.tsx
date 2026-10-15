import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { reportMetrics, type ReportVisit } from "@/lib/reports";
import { getMessages } from "@/lib/i18n/messages";
import { intlLocale } from "@/lib/i18n/locale";
import { getRequestLocale } from "@/lib/i18n/request-locale";

type SharedReport = {
  title: string;
  expiresAt: string;
  visits: Array<{
    id: string;
    approvedAt: string;
    companyName: string;
    summary: ReportVisit["summary"];
  }>;
};

export default async function SharedReportPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const { token } = await params;
  const locale = await getRequestLocale();
  const messages = getMessages(locale).sharedReport;
  if (!/^[a-f0-9]{64}$/.test(token)) notFound();
  const supabase = await createSupabaseServerClient();
  if (!supabase) notFound();
  const { data, error } = await supabase.rpc("get_shared_report", {
    share_token: token,
  });
  if (error || !data) notFound();
  const report = data as SharedReport;
  const visits: ReportVisit[] = report.visits.map((visit) => ({
    ...visit,
    representativeName: "",
    representativeId: "",
    companyId: "",
  }));
  const { positive, followUps } = reportMetrics(visits);

  return (
    <main className="shared-report-page">
      <header>
        <span className="eyebrow">{messages.eyebrow}</span>
        <h1>{report.title}</h1>
        <p>
          {messages.expires(
            new Intl.DateTimeFormat(intlLocale(locale), {
              dateStyle: "medium",
              timeStyle: "short",
            }).format(new Date(report.expiresAt)),
          )}
        </p>
      </header>
      <section className="report-metrics">
        <article>
          <small>{messages.approvedVisit}</small>
          <strong>{visits.length}</strong>
        </article>
        <article>
          <small>{messages.positiveOutcome}</small>
          <strong>
            %{visits.length ? Math.round((positive / visits.length) * 100) : 0}
          </strong>
        </article>
        <article>
          <small>{messages.followUps}</small>
          <strong>{followUps}</strong>
        </article>
      </section>
      <section className="shared-report-list">
        {visits.map((visit) => (
          <article key={visit.id}>
            <div>
              <strong>{visit.companyName}</strong>
              <time>
                {new Intl.DateTimeFormat(intlLocale(locale), {
                  dateStyle: "medium",
                }).format(new Date(visit.approvedAt))}
              </time>
            </div>
            <p>{visit.summary?.summary ?? messages.noApprovedSummary}</p>
          </article>
        ))}
      </section>
      <footer>{messages.footer}</footer>
    </main>
  );
}
