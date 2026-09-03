"use server";

import {
  companyCreateSchema,
  contactCreateSchema,
} from "@kartvizyon/contracts";
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
    displayName: formData.get("displayName"),
    phone: formData.get("phone"),
    email: formData.get("email"),
    website: formData.get("website"),
    address: formData.get("address"),
  });
  if (!parsed.success) redirect("/customers/new?error=validation");

  const contactFields = [
    "contactFirstName",
    "contactLastName",
    "contactTitle",
    "contactPhone",
    "contactEmail",
  ];
  const contactRequested = contactFields.some(
    (name) => (formData.get(name)?.toString().trim() ?? "").length > 0,
  );
  const contactDraft = contactCreateSchema.omit({ companyId: true }).safeParse({
    workspaceId: workspace.id,
    organizationId: workspace.organization_id,
    firstName: formData.get("contactFirstName"),
    lastName: formData.get("contactLastName"),
    title: formData.get("contactTitle"),
    phone: formData.get("contactPhone"),
    email: formData.get("contactEmail"),
  });
  if (contactRequested && !contactDraft.success)
    redirect("/customers/new?error=validation");

  const input = parsed.data;
  const { data: company, error } = await supabase
    .from("companies")
    .insert({
      workspace_id: input.workspaceId,
      organization_id: input.organizationId,
      name: input.name,
      display_name: input.displayName,
      phone: input.phone,
      email: input.email,
      website: input.website,
      address: input.address,
      created_by: user.id,
    })
    .select("id")
    .single();
  if (error) redirect("/customers/new?error=save");

  if (contactRequested && contactDraft.success) {
    const contact = contactDraft.data;
    const { error: contactError } = await supabase.from("contacts").insert({
      company_id: company.id,
      workspace_id: contact.workspaceId,
      organization_id: contact.organizationId,
      first_name: contact.firstName,
      last_name: contact.lastName,
      title: contact.title,
      phone: contact.phone,
      email: contact.email,
      created_by: user.id,
    });
    if (contactError) {
      await supabase.from("companies").delete().eq("id", company.id);
      redirect("/customers/new?error=contact");
    }
  }
  redirect("/customers");
}
