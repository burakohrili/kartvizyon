import Link from "next/link";
import { reportFiltersSchema, type ReportFilters } from "@kartvizyon/contracts";
import { loadApprovedReport, reportMetrics } from "@/lib/reports";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { ReportControls } from "./report-controls";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";
import { formatDate, intlLocale } from "@/lib/i18n/locale";

type SearchParams = Promise<Record<string, string | string[] | undefined>>;

function first(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

export default async function ReportsPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const locale = await getRequestLocale();
  const m = getMessages(locale).reports;
  const raw = await searchParams;
  const parsed = reportFiltersSchema.safeParse({
    from: first(raw.from) || undefined,
    to: first(raw.to) || undefined,
    representativeId: first(raw.representativeId) || undefined,
    companyId: first(raw.companyId) || undefined,
  });
  const filters: ReportFilters = parsed.success ? parsed.data : {};
  const [report, allReport] = await Promise.all([
    loadApprovedReport(filters),
    loadApprovedReport({}),
  ]);
  const { positive, followUps, companies } = reportMetrics(report.visits);
  const representatives = Array.from(
    new Map(
      allReport.visits.flatMap((visit) =>
        visit.representativeId
          ? [[visit.representativeId, visit.representativeName] as const]
          : [],
      ),
    ),
  );
  const companyOptions = Array.from(
    new Map(
      allReport.visits.map((visit) => [visit.companyId, visit.companyName]),
    ),
  );
  let shares: Array<{
    id: string;
    title: string;
    expires_at: string;
    revoked_at: string | null;
  }> = [];
  if (report.authenticated && report.workspaceId) {
    const supabase = await createSupabaseServerClient();
    const result = await supabase
      ?.from("report_shares")
      .select("id,title,expires_at,revoked_at")
      .eq("workspace_id", report.workspaceId)
      .order("created_at", { ascending: false })
      .limit(10);
    shares = result?.data ?? [];
  }

  return (
    <main className="customers-page reports-page">
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
      {report.demo && (
        <div className="demo-notice">
          <strong>{m.demoTitle}</strong> {m.demoBody}
        </div>
      )}
      <form className="report-filters" method="get">
        <label>
          {m.start}
          <input type="date" name="from" defaultValue={filters.from} />
        </label>
        <label>
          {m.end}
          <input type="date" name="to" defaultValue={filters.to} />
        </label>
        <label>
          {m.representative}
          <select
            name="representativeId"
            defaultValue={filters.representativeId ?? ""}
          >
            <option value="">{m.all}</option>
            {representatives.map(([id, name]) => (
              <option value={id} key={id}>
                {name}
              </option>
            ))}
          </select>
        </label>
        <label>
          {m.company}
          <select name="companyId" defaultValue={filters.companyId ?? ""}>
            <option value="">{m.all}</option>
            {companyOptions.map(([id, name]) => (
              <option value={id} key={id}>
                {name}
              </option>
            ))}
          </select>
        </label>
        <button className="primary" type="submit">
          {m.apply}
        </button>
        <Link href="/reports">{m.clear}</Link>
      </form>
      {!parsed.success && (
        <p className="form-message error">{m.invalidFilters}</p>
      )}
      <ReportControls
        filters={filters}
        workspaceId={report.workspaceId}
        authenticated={report.authenticated}
        initialShares={shares}
        locale={locale}
      />
      <section className="report-metrics">
        <article>
          <small>{m.approvedVisits}</small>
          <strong>{report.visits.length}</strong>
        </article>
        <article>
          <small>{m.positiveOutcome}</small>
          <strong>
            {new Intl.NumberFormat(intlLocale(locale), {
              style: "percent",
              maximumFractionDigits: 0,
            }).format(
              report.visits.length ? positive / report.visits.length : 0,
            )}
          </strong>
        </article>
        <article>
          <small>{m.createdFollowUps}</small>
          <strong>{followUps}</strong>
        </article>
      </section>
      <section className="report-panel">
        <div>
          <span className="eyebrow">{m.customerDistribution}</span>
          <h2>{m.mostVisitedCompanies}</h2>
        </div>
        {companies.length === 0 && (
          <p className="empty-state">{m.noApprovedVisits}</p>
        )}
        {companies.map(([name, count]) => (
          <article key={name}>
            <strong>{name}</strong>
            <span>
              {count} {m.approvedVisitCount}
            </span>
            <i
              style={{
                width: `${Math.max(8, (count / Math.max(1, report.visits.length)) * 100)}%`,
              }}
            />
          </article>
        ))}
      </section>
      <section className="report-visit-list">
        <div>
          <span className="eyebrow">{m.sourceRecords}</span>
          <h2>{m.approvedVisitsHeading}</h2>
        </div>
        {report.visits.map((visit) => (
          <article key={visit.id}>
            <div>
              <strong>{visit.companyName}</strong>
              <time>{formatDate(visit.approvedAt, locale)}</time>
            </div>
            <p>{visit.summary?.summary ?? m.noApprovedSummary}</p>
            <small>{visit.representativeName}</small>
          </article>
        ))}
      </section>
      <p className="report-privacy">{m.privacy}</p>
    </main>
  );
}
