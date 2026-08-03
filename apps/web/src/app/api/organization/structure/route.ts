import { regionCreateSchema, teamCreateSchema } from "@kartvizyon/contracts";
import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

const createSchema = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("region"), data: regionCreateSchema }),
  z.object({ kind: z.literal("team"), data: teamCreateSchema }),
]);

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const [regions, teams] = await Promise.all([
      context.supabase
        .from("regions")
        .select("*")
        .eq("workspace_id", context.workspaceId)
        .is("archived_at", null)
        .order("name"),
      context.supabase
        .from("teams")
        .select("*,region:regions(name),manager:profiles(full_name)")
        .eq("workspace_id", context.workspaceId)
        .is("archived_at", null)
        .order("name"),
    ]);
    if (regions.error) throw regions.error;
    if (teams.error) throw teams.error;
    return Response.json({ regions: regions.data, teams: teams.data });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    if (!context.organizationId)
      return Response.json(
        { error: "Takım ve bölge yalnızca şirket alanında kullanılabilir." },
        { status: 400 },
      );
    const input = createSchema.parse(await request.json());
    if (input.data.workspaceId !== context.workspaceId)
      return Response.json(
        { error: "Çalışma alanı uyuşmuyor." },
        { status: 403 },
      );
    const result =
      input.kind === "region"
        ? await context.supabase
            .from("regions")
            .insert({
              workspace_id: context.workspaceId,
              organization_id: context.organizationId,
              name: input.data.name,
              parent_region_id: input.data.parentRegionId ?? null,
              created_by: context.user.id,
            })
            .select("*")
            .single()
        : await context.supabase
            .from("teams")
            .insert({
              workspace_id: context.workspaceId,
              organization_id: context.organizationId,
              name: input.data.name,
              region_id: input.data.regionId ?? null,
              manager_id: input.data.managerId ?? null,
              created_by: context.user.id,
            })
            .select("*")
            .single();
    if (result.error) throw result.error;
    return Response.json({ data: result.data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
