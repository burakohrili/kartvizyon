import Link from "next/link";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { DebriefRecorder } from "./recorder";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function VisitDebriefPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const locale = await getRequestLocale();
  const m = getMessages(locale).debrief;
  const supabase = await createSupabaseServerClient();
  const ownerId = supabase
    ? ((await supabase.auth.getUser()).data.user?.id ?? "signed-out")
    : "demo-local";
  return (
    <main className="review-page">
      <DemoBanner />
      <section className="review-card debrief-card">
        <Link href="/visits" className="back-link">
          {m.back}
        </Link>
        <span className="eyebrow">{m.eyebrow}</span>
        <h1>{m.title}</h1>
        <p className="review-meta">{m.intro}</p>
        <DebriefRecorder visitId={id} ownerId={ownerId} locale={locale} />
      </section>
    </main>
  );
}
