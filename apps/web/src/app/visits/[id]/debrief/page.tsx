import Link from "next/link";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { DebriefRecorder } from "./recorder";

export default async function VisitDebriefPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createSupabaseServerClient();
  const ownerId = supabase
    ? ((await supabase.auth.getUser()).data.user?.id ?? "signed-out")
    : "demo-local";
  return (
    <main className="review-page">
      <section className="review-card debrief-card">
        <Link href="/visits" className="back-link">
          ← Ziyaretler
        </Link>
        <span className="eyebrow">ZİYARET SONRASI</span>
        <h1>Kısa değerlendirmeni kaydet</h1>
        <p className="review-meta">
          Bu, müşteri görüşmesinin kaydı değil; ziyaret bittikten sonra aldığın
          kişisel saha notudur. Ham ses yalnızca sana görünür ve 30 gün sonra
          silinmek üzere işaretlenir.
        </p>
        <DebriefRecorder visitId={id} ownerId={ownerId} />
      </section>
    </main>
  );
}
