import { z } from "zod";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";
const resultSchema = z.union([
  z.object({ error: z.string(), code: z.string() }),
  z.object({
    id: z.uuid(),
    completed: z.boolean(),
    response: z.unknown().optional(),
  }),
]);
export async function reserveAiQuota(input: {
  workspaceId: string;
  userId: string;
  key: string;
  ocr?: number;
  audioSeconds?: number;
  summaries?: number;
}) {
  const admin = createSupabaseAdminClient();
  if (!admin) throw new Error("Quota service unavailable");
  const { data, error } = await admin.rpc("reserve_ai_quota", {
    workspace_id_input: input.workspaceId,
    user_id_input: input.userId,
    request_key_input: input.key,
    ocr_input: input.ocr ?? 0,
    audio_seconds_input: input.audioSeconds ?? 0,
    summaries_input: input.summaries ?? 0,
  });
  if (error) throw error;
  const result = resultSchema.parse(data);
  if ("error" in result)
    return {
      denied: Response.json(result, {
        status: result.code === "operation_pending" ? 409 : 402,
      }),
    };
  return { operation: result };
}
export async function finishAiQuota(id: string, response: unknown) {
  const admin = createSupabaseAdminClient();
  if (!admin) throw new Error("Quota service unavailable");
  const { error } = await admin
    .from("ai_quota_operations")
    .update({ status: "completed", response })
    .eq("id", id)
    .eq("status", "reserved");
  if (error) throw error;
}
export async function releaseAiQuota(id: string) {
  const admin = createSupabaseAdminClient();
  if (!admin) throw new Error("Quota service unavailable");
  const { error } = await admin
    .from("ai_quota_operations")
    .update({ status: "failed" })
    .eq("id", id)
    .eq("status", "reserved");
  if (error) throw error;
}
