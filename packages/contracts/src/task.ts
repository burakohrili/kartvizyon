import { z } from "zod";

export const taskCreateSchema = z.object({
  workspaceId: z.uuid(),
  organizationId: z.uuid().nullable(),
  companyId: z.uuid().nullable(),
  visitId: z.uuid().nullable(),
  title: z.string().trim().min(1).max(180),
  dueAt: z.iso.datetime().nullable(),
  assignedTo: z.uuid().nullable(),
});

export const taskStatusSchema = z.enum(["open", "completed", "cancelled"]);

export type TaskCreate = z.infer<typeof taskCreateSchema>;
