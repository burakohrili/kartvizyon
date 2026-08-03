"use server";

import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function signOutEverywhere() {
  const supabase = await createSupabaseServerClient();
  if (!supabase) redirect("/login?error=config");
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const audit = await supabase.rpc("record_session_revocation");
  if (audit.error) redirect("/settings/security?error=audit");
  const { error } = await supabase.auth.signOut({ scope: "global" });
  if (error) redirect("/settings/security?error=signout");
  redirect("/login?message=signed-out-all");
}
