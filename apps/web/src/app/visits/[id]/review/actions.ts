"use server";

import { visitSummarySchema } from "@kartvizyon/contracts";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

async function sessionFor(id: string) {
  const supabase = await createSupabaseServerClient();
  if (!supabase) redirect(`/visits/${id}/review?error=config`);
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  return { supabase, user };
}

export async function approveVisit(formData: FormData) {
  const id = String(formData.get("visitId") ?? "");
  if (id.startsWith("demo-")) redirect("/visits?approved=demo");
  const { supabase, user } = await sessionFor(id);
  const current = await supabase
    .from("visits")
    .select("ai_summary")
    .eq("id", id)
    .eq("representative_id", user.id)
    .eq("status", "needs_review")
    .single();
  const parsed = visitSummarySchema.safeParse(current.data?.ai_summary);
  if (!parsed.success) redirect(`/visits/${id}/review?error=summary`);

  const selectedFollowUps = formData.getAll("followUps").map(String);
  const firstDate = String(formData.get("followUpDate") ?? "") || null;
  const aiSummary = visitSummarySchema.parse({
    ...parsed.data,
    summary: String(formData.get("summary") ?? ""),
    outcome: String(formData.get("outcome") ?? "unknown"),
    followUps: parsed.data.followUps
      .filter((item) => selectedFollowUps.includes(item.title))
      .map((item, index) => ({
        ...item,
        dueDate: index === 0 ? firstDate : item.dueDate,
      })),
  });

  const { error } = await supabase
    .from("visits")
    .update({
      ai_summary: aiSummary,
      status: "approved",
      approved_by: user.id,
      approved_at: new Date().toISOString(),
    })
    .eq("id", id)
    .eq("representative_id", user.id)
    .eq("status", "needs_review");
  if (error) redirect(`/visits/${id}/review?error=save`);
  redirect("/visits");
}

export async function returnVisitToDraft(formData: FormData) {
  const id = String(formData.get("visitId") ?? "");
  if (id.startsWith("demo-")) redirect("/visits");
  const { supabase, user } = await sessionFor(id);
  await supabase
    .from("visits")
    .update({ status: "draft", ai_summary: null, ai_schema_version: null })
    .eq("id", id)
    .eq("representative_id", user.id)
    .eq("status", "needs_review");
  redirect("/visits");
}
