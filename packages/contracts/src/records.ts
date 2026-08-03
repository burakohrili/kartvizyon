import { z } from "zod";

export const recordStatusSchema = z.enum([
  "draft",
  "processing",
  "needs_review",
  "approved",
  "rejected",
  "archived",
]);

export type RecordStatus = z.infer<typeof recordStatusSchema>;

const transitions: Record<RecordStatus, readonly RecordStatus[]> = {
  draft: ["processing", "archived"],
  processing: ["needs_review", "draft", "rejected"],
  needs_review: ["approved", "rejected", "draft"],
  approved: ["archived"],
  rejected: ["draft", "archived"],
  archived: [],
};

export function canTransition(from: RecordStatus, to: RecordStatus): boolean {
  return transitions[from].includes(to);
}

export function isManagerVisible(status: RecordStatus): boolean {
  return status === "approved";
}
