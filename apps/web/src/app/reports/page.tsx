import Link from "next/link";
import { reportFiltersSchema, type ReportFilters } from "@kartvizyon/contracts";
import { loadApprovedReport, reportMetrics } from "@/lib/reports";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { ReportControls } from "./report-controls";

type SearchParams = Promise<Record<string, string | string[] | undefined>>;

function first(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

export default async function ReportsPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
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
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">ONAYLI KAYITLAR</span>
          <h1>Satış aktivite raporu</h1>
          <p>Filtre, dışa aktar ve süreli bağlantıyla güvenle paylaş.</p>
        </div>
      </header>
      {report.demo && (
        <div className="demo-notice">
          <strong>Demo raporu.</strong> PDF ve Excel indirilebilir; güvenli
          paylaşım için Supabase oturumu gerekir.
        </div>
      )}
      <form className="report-filters" method="get">
        <label>
          Başlangıç
          <input type="date" name="from" defaultValue={filters.from} />
        </label>
        <label>
          Bitiş
          <input type="date" name="to" defaultValue={filters.to} />
        </label>
        <label>
          Temsilci
          <select
            name="representativeId"
            defaultValue={filters.representativeId ?? ""}
          >
            <option value="">Tümü</option>
            {representatives.map(([id, name]) => (
              <option value={id} key={id}>
                {name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Firma
          <select name="companyId" defaultValue={filters.companyId ?? ""}>
            <option value="">Tümü</option>
            {companyOptions.map(([id, name]) => (
              <option value={id} key={id}>
                {name}
              </option>
            ))}
          </select>
        </label>
        <button className="primary" type="submit">
          Uygula
        </button>
        <Link href="/reports">Temizle</Link>
      </form>
      {!parsed.success && (
        <p className="form-message error">
          Tarih veya filtre değeri geçersizdi; filtreler temizlendi.
        </p>
      )}
      <ReportControls
        filters={filters}
        workspaceId={report.workspaceId}
        authenticated={report.authenticated}
        initialShares={shares}
      />
      <section className="report-metrics">
        <article>
          <small>Onaylı ziyaret</small>
          <strong>{report.visits.length}</strong>
        </article>
        <article>
          <small>Olumlu sonuç</small>
          <strong>
            %
            {report.visits.length
              ? Math.round((positive / report.visits.length) * 100)
              : 0}
          </strong>
        </article>
        <article>
          <small>Oluşturulan takip</small>
          <strong>{followUps}</strong>
        </article>
      </section>
      <section className="report-panel">
        <div>
          <span className="eyebrow">MÜŞTERİ DAĞILIMI</span>
          <h2>En çok ziyaret edilen firmalar</h2>
        </div>
        {companies.length === 0 && (
          <p className="empty-state">
            Bu filtrelerde onaylı ziyaret bulunamadı.
          </p>
        )}
        {companies.map(([name, count]) => (
          <article key={name}>
            <strong>{name}</strong>
            <span>{count} onaylı ziyaret</span>
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
          <span className="eyebrow">KAYNAK KAYITLAR</span>
          <h2>Onaylı ziyaretler</h2>
        </div>
        {report.visits.map((visit) => (
          <article key={visit.id}>
            <div>
              <strong>{visit.companyName}</strong>
              <time>
                {new Date(visit.approvedAt).toLocaleDateString("tr-TR")}
              </time>
            </div>
            <p>{visit.summary?.summary ?? "Onaylı özet bulunmuyor."}</p>
            <small>{visit.representativeName}</small>
          </article>
        ))}
      </section>
      <p className="report-privacy">
        Taslaklar, onay bekleyen AI çıktıları, ham ses ve transkriptler rapora
        dahil edilmez.
      </p>
    </main>
  );
}
