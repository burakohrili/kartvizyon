import { z } from "zod";

export const visitCreateSchema = z
  .object({
    workspaceId: z.uuid(),
    organizationId: z.uuid().nullable(),
    companyId: z.uuid(),
    purpose: z.string().trim().max(500).optional(),
    visitType: z
      .enum([
        "sales_meeting",
        "quote_follow_up",
        "order_follow_up",
        "introduction",
        "technical",
        "other",
      ])
      .optional(),
    planningNote: z.string().trim().max(2000).nullable().optional(),
    plannedStartAt: z.iso.datetime().optional(),
    plannedEndAt: z.iso.datetime().optional(),
    startedAt: z.iso.datetime().optional(),
    clientMutationId: z.uuid(),
  })
  .refine(
    ({ plannedStartAt, plannedEndAt }) =>
      (!plannedStartAt && !plannedEndAt) ||
      (!!plannedStartAt &&
        !!plannedEndAt &&
        new Date(plannedStartAt) < new Date(plannedEndAt)),
    "Ziyaret bitişi başlangıçtan sonra olmalıdır.",
  );

export const visitApprovalSchema = z.object({
  visitId: z.uuid(),
  expectedStatus: z.literal("needs_review"),
});

export type VisitCreate = z.infer<typeof visitCreateSchema>;
