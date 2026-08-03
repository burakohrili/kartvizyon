import { orderDraftStatusSchema } from "@/lib/order-status";
import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

const transitionSchema = z.object({
  status: orderDraftStatusSchema.extract([
    "pending_approval",
    "approved",
    "rejected",
  ]),
  rejectionReason: z.string().trim().min(2).max(500).nullable().optional(),
});

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { id } = await params;
    const orderId = z.uuid().parse(id);
    const input = transitionSchema.parse(await request.json());
    const { error } = await context.supabase.rpc("transition_order_draft", {
      target_order_id: orderId,
      target_status: input.status,
      rejection_reason: input.rejectionReason ?? null,
    });
    if (error) throw error;
    return Response.json({ transitioned: true, status: input.status });
  } catch (error) {
    return apiError(error);
  }
}
