import { z } from "zod";
import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

const eventSchema = z.object({
  workspaceId: z.uuid(),
  organizationId: z.uuid().nullable(),
  companyId: z.uuid(),
  priorityScore: z.number().int().min(0).max(100),
  distanceMeters: z.number().int().min(0),
  outcome: z.enum([
    "shown",
    "briefing_opened",
    "navigation_opened",
    "dismissed",
  ]),
});

export async function POST(request: Request) {
  try {
    const input = eventSchema.parse(await request.json());
    const supabase = await createSupabaseServerClient();
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });
    const { error } = await supabase.from("geofence_events").insert({
      workspace_id: input.workspaceId,
      organization_id: input.organizationId,
      user_id: user.id,
      company_id: input.companyId,
      priority_score: input.priorityScore,
      distance_meters: input.distanceMeters,
      outcome: input.outcome,
    });
    if (error) return apiError(error);
    return new Response(null, { status: 204 });
  } catch (error) {
    return apiError(error);
  }
}
