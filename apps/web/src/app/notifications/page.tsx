import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { NotificationCenter } from "../interaction-workbench";
import { DemoBanner } from "@/app/demo-banner";
import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export default async function NotificationsPage() {
  const [context, locale] = await Promise.all([
    getWebWorkspaceContext(),
    getRequestLocale(),
  ]);
  const m = getMessages(locale).notifications;
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
            {m.back}
          </Link>
          <span className="eyebrow">{m.eyebrow}</span>
          <h1>{m.title}</h1>
          <p>{m.description}</p>
        </div>
      </header>
      <NotificationCenter
        initialItems={(result.data ?? []) as Array<Record<string, unknown>>}
        locale={locale}
      />
    </main>
  );
}
