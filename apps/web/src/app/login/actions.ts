"use server";

import { redirect } from "next/navigation";
import { headers } from "next/headers";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function signIn(formData: FormData) {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const supabase = await createSupabaseServerClient();
  if (!supabase) redirect("/login?error=config");
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) redirect("/login?error=credentials");
  redirect("/dashboard");
}

export async function signUp(formData: FormData) {
  const fullName = String(formData.get("fullName") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");
  const supabase = await createSupabaseServerClient();
  if (!supabase) redirect("/login?error=config");
  const requestHeaders = await headers();
  const origin =
    requestHeaders.get("origin") ??
    process.env.NEXT_PUBLIC_APP_URL ??
    "https://app.kartvizyon.app";
  const emailRedirectTo = new URL(
    "/auth/callback?next=/dashboard",
    origin,
  ).toString();
  const { error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { full_name: fullName }, emailRedirectTo },
  });
  if (error) redirect("/login?error=signup");
  redirect("/login?message=verify");
}
