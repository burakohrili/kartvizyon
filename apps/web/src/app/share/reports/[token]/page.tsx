import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { reportMetrics, type ReportVisit } from "@/lib/reports";

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
        <span className="eyebrow">KARTVİZYON AI · GÜVENLİ RAPOR</span>
        <h1>{report.title}</h1>
        <p>
          Bağlantı {new Date(report.expiresAt).toLocaleString("tr-TR")} tarihine
          kadar geçerlidir.
        </p>
      </header>
      <section className="report-metrics">
        <article>
          <small>Onaylı ziyaret</small>
          <strong>{visits.length}</strong>
        </article>
        <article>
          <small>Olumlu sonuç</small>
          <strong>
            %{visits.length ? Math.round((positive / visits.length) * 100) : 0}
          </strong>
        </article>
        <article>
          <small>Takip</small>
          <strong>{followUps}</strong>
        </article>
      </section>
      <section className="shared-report-list">
        {visits.map((visit) => (
          <article key={visit.id}>
            <div>
              <strong>{visit.companyName}</strong>
              <time>
                {new Date(visit.approvedAt).toLocaleDateString("tr-TR")}
              </time>
            </div>
            <p>{visit.summary?.summary ?? "Onaylı özet bulunmuyor."}</p>
          </article>
        ))}
      </section>
      <footer>Bu rapor yalnızca onaylanmış kayıtlardan oluşturulmuştur.</footer>
    </main>
  );
}
