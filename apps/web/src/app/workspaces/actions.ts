"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function selectWorkspace(formData: FormData) {
  const workspaceId = String(formData.get("workspaceId") ?? "");
  if (!workspaceId) redirect("/workspaces?error=workspace");
  if (!workspaceId.startsWith("demo-")) {
    const supabase = await createSupabaseServerClient();
    if (!supabase) redirect("/workspaces?error=config");
    const { data } = await supabase
      .from("workspaces")
      .select("id")
      .eq("id", workspaceId)
      .single();
    if (!data) redirect("/workspaces?error=access");
  }
  const cookieStore = await cookies();
  cookieStore.set("kartvizyon_workspace", workspaceId, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 60 * 60 * 24 * 30,
  });
  redirect("/");
}

export async function createOrganization(formData: FormData) {
  const name = String(formData.get("name") ?? "").trim();
  const slug = String(formData.get("slug") ?? "")
    .trim()
    .toLocaleLowerCase("tr-TR");
  const supabase = await createSupabaseServerClient();
  if (!supabase) redirect("/workspaces?error=config");
  const { data, error } = await supabase.rpc("create_organization", {
    organization_name: name,
    organization_slug: slug,
  });
  if (error || !data) redirect("/workspaces?error=create");
  const { data: workspace } = await supabase
    .from("workspaces")
    .select("id")
    .eq("organization_id", data)
    .single();
  if (workspace) {
    const cookieStore = await cookies();
    cookieStore.set("kartvizyon_workspace", workspace.id, {
      httpOnly: true,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      path: "/",
    });
  }
  redirect("/");
}
