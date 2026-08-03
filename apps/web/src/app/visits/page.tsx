import Link from "next/link";
import { createSupabaseServerClient } from "@/lib/supabase/server";

type Visit = {
  id: string;
  status: string;
  purpose: string | null;
  completed_at: string | null;
  company: { name: string } | null;
};
const demos: Visit[] = [
  {
    id: "demo-review",
    status: "needs_review",
    purpose: "Yeni cihaz teklifi",
    completed_at: "2026-08-02T10:42:00Z",
    company: { name: "Atlas Medikal" },
  },
  {
    id: "demo-approved",
    status: "approved",
    purpose: "Bakım sözleşmesi",
    completed_at: "2026-08-01T15:10:00Z",
    company: { name: "Nova Otomasyon" },
  },
  {
    id: "demo-draft",
    status: "draft",
    purpose: "Fiyat görüşmesi",
    completed_at: null,
    company: { name: "Marmara Ambalaj" },
  },
];

async function getVisits(): Promise<{ visits: Visit[]; demo: boolean }> {
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

const labels: Record<string, string> = {
  draft: "Taslak",
  processing: "İşleniyor",
  needs_review: "Onay bekliyor",
  approved: "Onaylandı",
  rejected: "Reddedildi",
  archived: "Arşivlendi",
};

export default async function VisitsPage() {
  const { visits, demo } = await getVisits();
  return (
    <main className="customers-page">
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">SAHA AKTİVİTESİ</span>
          <h1>Ziyaretler</h1>
          <p>
            Taslaklardan onaylanmış kurumsal kayıtlara kadar tüm ziyaret akışı.
          </p>
        </div>
        <Link href="/visits/demo-draft/debrief" className="primary">
          + Ziyaret kaydet
        </Link>
      </header>
      {demo && (
        <div className="demo-notice">
          <strong>Demo akışı.</strong> Canlı veriler Supabase bağlantısından
          sonra RLS kurallarıyla listelenir.
        </div>
      )}
      <section className="visit-summary-row">
        <article>
          <small>Onay bekliyor</small>
          <strong>
            {visits.filter((v) => v.status === "needs_review").length}
          </strong>
        </article>
        <article>
          <small>Onaylandı</small>
          <strong>
            {visits.filter((v) => v.status === "approved").length}
          </strong>
        </article>
        <article>
          <small>Taslak</small>
          <strong>{visits.filter((v) => v.status === "draft").length}</strong>
        </article>
      </section>
      <section className="visit-list">
        {visits.map((visit) => (
          <article key={visit.id}>
            <span className={`status-dot ${visit.status}`} />
            <div>
              <strong>{visit.company?.name ?? "Firma bulunamadı"}</strong>
              <p>{visit.purpose ?? "Ziyaret amacı eklenmedi"}</p>
              <small>
                {visit.completed_at
                  ? new Intl.DateTimeFormat("tr-TR", {
                      dateStyle: "medium",
                      timeStyle: "short",
                    }).format(new Date(visit.completed_at))
                  : "Henüz tamamlanmadı"}
              </small>
            </div>
            <span className={`status-pill ${visit.status}`}>
              {labels[visit.status] ?? visit.status}
            </span>
            {visit.status === "needs_review" ? (
              <Link href={`/visits/${visit.id}/review`}>İncele →</Link>
            ) : visit.status === "draft" ? (
              <Link href={`/visits/${visit.id}/debrief`}>Not ekle →</Link>
            ) : (
              <button aria-label="Ziyaret menüsü">•••</button>
            )}
          </article>
        ))}
      </section>
    </main>
  );
}
