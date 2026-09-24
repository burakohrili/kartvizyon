import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

const identitySchema = z.object({
  companyName: z.string().trim().min(2).max(160),
  displayName: z.string().trim().min(2).max(120).optional(),
});

export async function PATCH(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = identitySchema.parse(await request.json());
    const renamed = await context.supabase.rpc("rename_workspace_company", {
      target_workspace_id: context.workspaceId,
      company_name: input.companyName,
    });
    if (renamed.error) throw renamed.error;
    if (input.displayName !== undefined) {
      const profile = await context.supabase
        .from("profiles")
        .update({
          full_name: input.displayName,
          updated_at: new Date().toISOString(),
        })
        .eq("id", context.user.id);
      if (profile.error) throw profile.error;
    }
    return Response.json({
      companyName: input.companyName,
      displayName: input.displayName ?? null,
    });
  } catch (error) {
    return apiError(error);
  }
}
