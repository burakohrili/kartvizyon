import { z } from "zod";

export const orderDraftStatusSchema = z.enum([
  "draft",
  "pending_approval",
  "approved",
  "rejected",
  "exported",
  "cancelled",
]);
