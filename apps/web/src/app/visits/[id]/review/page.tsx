import { visitSummarySchema, type VisitSummary } from "@kartvizyon/contracts";
import Link from "next/link";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { approveVisit, returnVisitToDraft } from "./actions";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

const demoSummary: VisitSummary = {
  summary:
    "Müşteri yeni cihaz serisi için teknik demo talep etti. Revize teklifin cuma gününe kadar iletilmesi ve satın alma müdürüyle ikinci görüşme planlanması kararlaştırıldı.",
  outcome: "positive",
  customerNeeds: ["Yeni cihaz serisi için teknik demo"],
  promises: ["Revize teklifi cuma gününe kadar iletmek"],
  followUps: [
    {
      title: "Teknik demo tarihini netleştir",
      dueDate: "2026-08-07",
      ownerHint: null,
    },
  ],
  sensitiveContentDetected: false,
  confidence: 0.89,
};

async function getVisit(id: string) {
  if (id.startsWith("demo-")) {
    return {
      companyName: "Atlas Medikal",
      purpose: "Yeni cihaz teklifi",
      summary: demoSummary,
    };
  }
  const supabase = await createSupabaseServerClient();
  if (!supabase) return null;
  const { data } = await supabase
    .from("visits")
    .select("purpose,ai_summary,company:companies(name)")
    .eq("id", id)
    .eq("status", "needs_review")
    .single();
  if (!data) return null;
  const company = data.company as unknown as { name: string } | null;
  const parsed = visitSummarySchema.safeParse(data.ai_summary);
  return {
    companyName: company?.name ?? "Firma",
    purpose: data.purpose as string | null,
    summary: parsed.success ? parsed.data : demoSummary,
  };
}

export default async function VisitReviewPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const locale = await getRequestLocale();
  const m = getMessages(locale).review;
  const visit = await getVisit(id);

  if (!visit) {
    return (
      <main className="review-page">
        <DemoBanner />
        <section className="review-card">
          <Link href="/visits" className="back-link">
            {m.back}
          </Link>
          <h1>{m.notFound}</h1>
        </section>
      </main>
    );
  }

  return (
    <main className="review-page">
      <section className="review-card">
        <Link href="/visits" className="back-link">
          {m.back}
        </Link>
        <div className="ai-label">{m.aiReview}</div>
        <h1>
          {visit.companyName} {m.visitSuffix}
        </h1>
        <p className="review-meta">{visit.purpose ?? m.debriefPurpose}</p>
        <form action={approveVisit}>
          <input type="hidden" name="visitId" value={id} />
          <label className="review-field">
            {m.summary}
            <textarea
              name="summary"
              defaultValue={visit.summary.summary}
              rows={5}
              required
              minLength={10}
              maxLength={1200}
            />
          </label>
          <div className="review-grid">
            <label className="review-field">
              {m.outcome}
              <select name="outcome" defaultValue={visit.summary.outcome}>
                <option value="positive">{m.positive}</option>
                <option value="neutral">{m.neutral}</option>
                <option value="negative">{m.negative}</option>
                <option value="unknown">{m.unknown}</option>
              </select>
            </label>
            <label className="review-field">
              {m.firstFollowUpDate}
              <input
                name="followUpDate"
                type="date"
                defaultValue={visit.summary.followUps[0]?.dueDate ?? ""}
              />
            </label>
          </div>
          <section className="ai-actions">
            <strong>{m.recommendedFollowUps}</strong>
            {visit.summary.followUps.length ? (
              visit.summary.followUps.map((followUp, index) => (
                <label key={`${followUp.title}-${index}`}>
                  <input
                    type="checkbox"
                    name="followUps"
                    value={followUp.title}
                    defaultChecked
                  />{" "}
                  {followUp.title}
                </label>
              ))
            ) : (
              <small>{m.noSuggestions}</small>
            )}
          </section>
          <div className="sensitive-check">
            {visit.summary.sensitiveContentDetected
              ? m.sensitiveWarning
              : m.noSensitiveData}
          </div>
          <div className="review-buttons">
            <button formAction={returnVisitToDraft} className="reject-button">
              {m.returnToDraft}
            </button>
            <button type="submit" className="primary">
              {m.approve}
            </button>
          </div>
        </form>
      </section>
    </main>
  );
}
