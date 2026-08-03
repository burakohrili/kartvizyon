"use server";

import { contactCreateSchema } from "@kartvizyon/contracts";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function createContact(formData: FormData) {
  const companyId = String(formData.get("companyId") ?? "");
  if (companyId.startsWith("demo-")) redirect(`/customers/${companyId}`);
  const supabase = await createSupabaseServerClient();
  if (!supabase) redirect(`/customers/${companyId}/contacts/new?error=config`);
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: company } = await supabase
    .from("companies")
    .select("workspace_id,organization_id")
    .eq("id", companyId)
    .single();
  if (!company) redirect(`/customers/${companyId}/contacts/new?error=company`);
  const parsed = contactCreateSchema.safeParse({
    companyId,
    workspaceId: company.workspace_id,
    organizationId: company.organization_id,
    firstName: formData.get("firstName"),
    lastName: formData.get("lastName"),
    title: formData.get("title"),
    phone: formData.get("phone"),
    email: formData.get("email"),
  });
  if (!parsed.success)
    redirect(`/customers/${companyId}/contacts/new?error=validation`);
  const input = parsed.data;
  const { error } = await supabase.from("contacts").insert({
    company_id: input.companyId,
    workspace_id: input.workspaceId,
    organization_id: input.organizationId,
    first_name: input.firstName,
    last_name: input.lastName,
    title: input.title,
    phone: input.phone,
    email: input.email,
    created_by: user.id,
  });
  if (error) redirect(`/customers/${companyId}/contacts/new?error=save`);
  redirect(`/customers/${companyId}`);
}
