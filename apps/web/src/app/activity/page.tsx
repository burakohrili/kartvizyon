import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { ActivityFeed } from "../interaction-workbench";
import { DemoBanner } from "@/app/demo-banner";

const demoVisits = [
  {
    id: "00000000-0000-4000-8000-000000000701",
    approved_at: new Date().toISOString(),
    company: { name: "Atlas Medikal" },
    representative: { full_name: "Ece Yılmaz" },
    ai_summary: {
      summary: "Yeni cihaz teklifi ve teknik demo tarihi onaylandı.",
    },
  },
];

export default async function ActivityPage() {
  const context = await getWebWorkspaceContext();
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
            ← Genel bakış
          </Link>
          <span className="eyebrow">YÖNETİCİ AKTİVİTESİ</span>
          <h1>Onaylı saha akışı</h1>
          <p>
            Yalnızca temsilcinin onayladığı ziyaretler, yorumlar ve
            yönlendirmeler.
          </p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          Demo akışı; yorum için Supabase oturumu gerekir.
        </div>
      )}
      <ActivityFeed
        initialVisits={(visits.data ?? []) as Item[]}
        initialComments={(comments.data ?? []) as Item[]}
      />
    </main>
  );
}
type Item = Record<string, unknown>;
