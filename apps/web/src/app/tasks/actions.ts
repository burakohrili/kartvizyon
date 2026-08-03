"use server";

import { revalidatePath } from "next/cache";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function completeTask(formData: FormData) {
  const id = String(formData.get("taskId") ?? "");
  if (id.startsWith("demo-")) return;
  const supabase = await createSupabaseServerClient();
  if (!supabase) return;
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return;
  await supabase
    .from("tasks")
    .update({ status: "completed", completed_at: new Date().toISOString() })
    .eq("id", id)
    .eq("assigned_to", user.id)
    .eq("status", "open");
  revalidatePath("/tasks");
}
