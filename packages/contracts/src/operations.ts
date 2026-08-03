import { z } from "zod";

const nullableUuid = z.uuid().nullable().optional();

export const opportunityStageSchema = z.enum([
  "lead",
  "qualified",
  "proposal",
  "negotiation",
  "won",
  "lost",
]);

export const opportunityCreateSchema = z.object({
  workspaceId: z.uuid(),
  companyId: z.uuid(),
  title: z.string().trim().min(2).max(180),
  stage: opportunityStageSchema.default("lead"),
  estimatedValue: z.number().nonnegative().max(1_000_000_000).default(0),
  currency: z.enum(["TRY", "USD", "EUR"]).default("TRY"),
  probability: z.number().int().min(0).max(100).default(10),
  expectedCloseDate: z.iso.date().nullable().optional(),
  competitor: z.string().trim().max(160).nullable().optional(),
  assignedTo: nullableUuid,
});

export const productCreateSchema = z.object({
  workspaceId: z.uuid(),
  sku: z.string().trim().min(1).max(80),
  name: z.string().trim().min(2).max(180),
  unit: z.string().trim().min(1).max(40).default("adet"),
  taxRate: z.number().min(0).max(100).default(20),
  listPrice: z.number().nonnegative().max(1_000_000_000),
  currency: z.enum(["TRY", "USD", "EUR"]).default("TRY"),
});

export const orderItemSchema = z.object({
  productId: z.uuid(),
  quantity: z.number().positive().max(1_000_000),
  unitPrice: z.number().nonnegative().max(1_000_000_000),
  discountPercent: z.number().min(0).max(100).default(0),
});

export const orderDraftCreateSchema = z.object({
  workspaceId: z.uuid(),
  companyId: z.uuid(),
  opportunityId: nullableUuid,
  deliveryDate: z.iso.date().nullable().optional(),
  notes: z.string().trim().max(2000).nullable().optional(),
  currency: z.enum(["TRY", "USD", "EUR"]).default("TRY"),
  items: z.array(orderItemSchema).min(1).max(200),
});

export const plannedVisitCreateSchema = z
  .object({
    workspaceId: z.uuid(),
    companyId: z.uuid(),
    representativeId: z.uuid(),
    purpose: z.string().trim().min(2).max(500),
    plannedStartAt: z.iso.datetime(),
    plannedEndAt: z.iso.datetime(),
  })
  .refine(
    ({ plannedStartAt, plannedEndAt }) =>
      new Date(plannedStartAt) < new Date(plannedEndAt),
    "Ziyaret bitişi başlangıçtan sonra olmalıdır.",
  );

export const regionCreateSchema = z.object({
  workspaceId: z.uuid(),
  name: z.string().trim().min(2).max(120),
  parentRegionId: nullableUuid,
});

export const teamCreateSchema = z.object({
  workspaceId: z.uuid(),
  name: z.string().trim().min(2).max(120),
  regionId: nullableUuid,
  managerId: nullableUuid,
});

export type OpportunityCreate = z.infer<typeof opportunityCreateSchema>;
export type ProductCreate = z.infer<typeof productCreateSchema>;
export type OrderDraftCreate = z.infer<typeof orderDraftCreateSchema>;
