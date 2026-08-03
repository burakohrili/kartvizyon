import { activityCommentCreateSchema } from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const visitId = new URL(request.url).searchParams.get("visitId");
    let query = context.supabase
      .from("activity_comments")
      .select("*,author:profiles(full_name)")
      .eq("workspace_id", context.workspaceId)
      .is("deleted_at", null)
      .order("created_at");
    if (visitId) query = query.eq("visit_id", visitId);
    const { data, error } = await query.limit(500);
    if (error) throw error;
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = activityCommentCreateSchema.parse(await request.json());
    const { data, error } = await context.supabase.rpc(
      "create_activity_comment",
      { target_visit_id: input.visitId, comment_body: input.body },
    );
    if (error) throw error;
    return Response.json({ id: data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
