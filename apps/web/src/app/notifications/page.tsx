import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { NotificationCenter } from "../interaction-workbench";
import { DemoBanner } from "@/app/demo-banner";

export default async function NotificationsPage() {
  const context = await getWebWorkspaceContext();
  const result = context
    ? await context.supabase
        .from("notifications")
        .select("*")
        .eq("user_id", context.user.id)
        .order("created_at", { ascending: false })
        .limit(100)
    : { data: [] };
  return (
    <main className="customers-page">
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">BİLDİRİMLER</span>
          <h1>Bildirim merkezi</h1>
          <p>Yönetici yorumları, görevler, onaylar ve eşitleme olayları.</p>
        </div>
      </header>
      <NotificationCenter
        initialItems={(result.data ?? []) as Array<Record<string, unknown>>}
      />
    </main>
  );
}
