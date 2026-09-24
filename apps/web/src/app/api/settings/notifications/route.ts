import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

const preferencesSchema = z.object({
  visitReminders: z.boolean(),
  taskReminders: z.boolean(),
  fieldModeMorning: z.boolean(),
});

const defaults = {
  visitReminders: true,
  taskReminders: true,
  fieldModeMorning: true,
};

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { data, error } = await context.supabase
      .from("notification_preferences")
      .select("visit_reminders,task_reminders,field_mode_morning")
      .eq("user_id", context.user.id)
      .eq("workspace_id", context.workspaceId)
      .maybeSingle();
    if (error) throw error;
    return Response.json({
      data: data
        ? {
            visitReminders: data.visit_reminders,
            taskReminders: data.task_reminders,
            fieldModeMorning: data.field_mode_morning,
          }
        : defaults,
    });
  } catch (error) {
    return apiError(error);
  }
}

export async function PATCH(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = preferencesSchema.parse(await request.json());
    const { error } = await context.supabase
      .from("notification_preferences")
      .upsert(
        {
          user_id: context.user.id,
          workspace_id: context.workspaceId,
          visit_reminders: input.visitReminders,
          task_reminders: input.taskReminders,
          field_mode_morning: input.fieldModeMorning,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id,workspace_id" },
      );
    if (error) throw error;
    return Response.json({ updated: true });
  } catch (error) {
    return apiError(error);
  }
}
