"use server";

import { companyCreateSchema } from "@kartvizyon/contracts";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function createCompany(formData: FormData) {
  const supabase = await createSupabaseServerClient();
  if (!supabase) redirect("/customers/new?error=config");
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: workspace } = await supabase
    .from("workspaces")
    .select("id,organization_id")
    .limit(1)
    .single();
  if (!workspace) redirect("/customers/new?error=workspace");
  const parsed = companyCreateSchema.safeParse({
    workspaceId: workspace.id,
    organizationId: workspace.organization_id,
    name: formData.get("name"),
    phone: formData.get("phone"),
    email: formData.get("email"),
    website: formData.get("website"),
    address: formData.get("address"),
  });
  if (!parsed.success) redirect("/customers/new?error=validation");
  const input = parsed.data;
  const { error } = await supabase.from("companies").insert({
    workspace_id: input.workspaceId,
    organization_id: input.organizationId,
    name: input.name,
    phone: input.phone,
    email: input.email,
    website: input.website,
    address: input.address,
    created_by: user.id,
  });
  if (error) redirect("/customers/new?error=save");
  redirect("/customers");
}
