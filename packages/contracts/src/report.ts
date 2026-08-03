import { z } from "zod";

export const reportFiltersSchema = z
  .object({
    from: z.iso.date().optional(),
    to: z.iso.date().optional(),
    representativeId: z.uuid().optional(),
    companyId: z.uuid().optional(),
  })
  .refine(
    ({ from, to }) => !from || !to || new Date(from) <= new Date(to),
    "Başlangıç tarihi bitiş tarihinden sonra olamaz.",
  );

export const reportShareCreateSchema = z.object({
  workspaceId: z.uuid(),
  title: z.string().trim().min(2).max(160),
  filters: reportFiltersSchema.default({}),
  validForHours: z
    .number()
    .int()
    .min(1)
    .max(24 * 30)
    .default(168),
});

export const reportShareRevokeSchema = z.object({
  shareId: z.uuid(),
});

export type ReportFilters = z.infer<typeof reportFiltersSchema>;
export type ReportShareCreate = z.infer<typeof reportShareCreateSchema>;
