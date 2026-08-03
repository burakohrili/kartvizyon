import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { data, error } = await context.supabase
      .from("notifications")
      .select("*")
      .eq("user_id", context.user.id)
      .order("created_at", { ascending: false })
      .limit(100);
    if (error) throw error;
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}

export async function PATCH(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { id } = z.object({ id: z.uuid() }).parse(await request.json());
    const { error } = await context.supabase
      .from("notifications")
      .update({ read_at: new Date().toISOString() })
      .eq("id", id)
      .eq("user_id", context.user.id);
    if (error) throw error;
    return Response.json({ read: true });
  } catch (error) {
    return apiError(error);
  }
}
