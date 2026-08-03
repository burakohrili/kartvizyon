import {
  formSubmissionCreateSchema,
  formTemplateCreateSchema,
} from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const [templates, submissions] = await Promise.all([
      context.supabase
        .from("form_templates")
        .select("*")
        .eq("workspace_id", context.workspaceId)
        .eq("active", true)
        .order("name"),
      context.supabase
        .from("form_submissions")
        .select("*,template:form_templates(name)")
        .eq("workspace_id", context.workspaceId)
        .order("submitted_at", { ascending: false })
        .limit(100),
    ]);
    if (templates.error) throw templates.error;
    if (submissions.error) throw submissions.error;
    return Response.json({
      templates: templates.data,
      submissions: submissions.data,
    });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const body = await request.json();
    if (body.kind === "template") {
      const input = formTemplateCreateSchema.parse(body.data);
      if (input.workspaceId !== context.workspaceId)
        return Response.json(
          { error: "Çalışma alanı uyuşmuyor." },
          { status: 403 },
        );
      const { data, error } = await context.supabase
        .from("form_templates")
        .insert({
          workspace_id: context.workspaceId,
          organization_id: context.organizationId,
          name: input.name,
          description: input.description ?? null,
          fields: input.fields,
          created_by: context.user.id,
        })
        .select("*")
        .single();
      if (error) throw error;
      return Response.json({ data }, { status: 201 });
    }
    const input = formSubmissionCreateSchema.parse(body.data);
    const template = await context.supabase
      .from("form_templates")
      .select("id,workspace_id")
      .eq("id", input.templateId)
      .eq("workspace_id", context.workspaceId)
      .single();
    if (template.error) throw template.error;
    const { data, error } = await context.supabase
      .from("form_submissions")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        template_id: input.templateId,
        company_id: input.companyId ?? null,
        visit_id: input.visitId ?? null,
        submitted_by: context.user.id,
        data: input.data,
      })
      .select("*")
      .single();
    if (error) throw error;
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
