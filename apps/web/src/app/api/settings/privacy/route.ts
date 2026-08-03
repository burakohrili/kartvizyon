import {
  consentUpdateSchema,
  privacyRequestSchema,
} from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const [consents, requests] = await Promise.all([
      context.supabase
        .from("user_consents")
        .select("purpose,granted,policy_version,recorded_at,revoked_at")
        .eq("workspace_id", context.workspaceId)
        .eq("user_id", context.user.id),
      context.supabase
        .from("privacy_requests")
        .select(
          "id,kind,status,requested_at,due_at,completed_at,resolution_note",
        )
        .eq("workspace_id", context.workspaceId)
        .eq("user_id", context.user.id)
        .order("requested_at", { ascending: false }),
    ]);
    if (consents.error) throw consents.error;
    if (requests.error) throw requests.error;
    return Response.json({ consents: consents.data, requests: requests.data });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = privacyRequestSchema.parse(await request.json());
    if (input.workspaceId !== context.workspaceId)
      return Response.json(
        { error: "Çalışma alanı uyuşmuyor." },
        { status: 403 },
      );
    const { data: existing } = await context.supabase
      .from("privacy_requests")
      .select("id")
      .eq("workspace_id", context.workspaceId)
      .eq("user_id", context.user.id)
      .eq("kind", input.kind)
      .in("status", ["requested", "processing", "ready"])
      .maybeSingle();
    if (existing)
      return Response.json(
        { error: "Bu türde açık bir talebiniz zaten var." },
        { status: 409 },
      );
    const { data, error } = await context.supabase
      .from("privacy_requests")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        user_id: context.user.id,
        kind: input.kind,
        reason: input.reason,
      })
      .select("id,kind,status,requested_at,due_at")
      .single();
    if (error) throw error;
    await context.supabase.from("audit_logs").insert({
      organization_id: context.organizationId,
      workspace_id: context.workspaceId,
      actor_id: context.user.id,
      action: `privacy.${input.kind}_requested`,
      resource_type: "privacy_request",
      resource_id: data.id,
    });
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}

export async function PATCH(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = consentUpdateSchema.parse(await request.json());
    if (input.workspaceId !== context.workspaceId)
      return Response.json(
        { error: "Çalışma alanı uyuşmuyor." },
        { status: 403 },
      );
    const now = new Date().toISOString();
    const { data, error } = await context.supabase
      .from("user_consents")
      .upsert(
        {
          workspace_id: context.workspaceId,
          organization_id: context.organizationId,
          user_id: context.user.id,
          purpose: input.purpose,
          granted: input.granted,
          recorded_at: now,
          revoked_at: input.granted ? null : now,
        },
        { onConflict: "workspace_id,user_id,purpose" },
      )
      .select("purpose,granted,recorded_at,revoked_at")
      .single();
    if (error) throw error;
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}
