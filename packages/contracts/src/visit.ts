import { z } from "zod";

export const visitCreateSchema = z.object({
  workspaceId: z.uuid(),
  organizationId: z.uuid().nullable(),
  companyId: z.uuid(),
  purpose: z.string().trim().max(500).optional(),
  startedAt: z.iso.datetime().optional(),
  clientMutationId: z.uuid(),
});

export const visitApprovalSchema = z.object({
  visitId: z.uuid(),
  expectedStatus: z.literal("needs_review"),
});

export type VisitCreate = z.infer<typeof visitCreateSchema>;
