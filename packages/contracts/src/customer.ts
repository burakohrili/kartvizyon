import { z } from "zod";

const optionalText = (max: number) =>
  z
    .string()
    .trim()
    .max(max)
    .optional()
    .transform((value) => value || undefined);

export const companyCreateSchema = z.object({
  workspaceId: z.uuid(),
  organizationId: z.uuid().nullable(),
  name: z.string().trim().min(2).max(200),
  phone: optionalText(40),
  email: z
    .union([z.email(), z.literal("")])
    .optional()
    .transform((value) => value || undefined),
  website: z
    .union([z.url(), z.literal("")])
    .optional()
    .transform((value) => value || undefined),
  address: optionalText(500),
  clientMutationId: z.uuid().optional(),
});

export const duplicateCheckSchema = z.object({
  workspaceId: z.uuid(),
  name: z.string().trim().min(2).max(200),
  email: z.email().optional(),
  phone: optionalText(40),
});

export const contactCreateSchema = z.object({
  companyId: z.uuid(),
  workspaceId: z.uuid(),
  organizationId: z.uuid().nullable(),
  firstName: z.string().trim().min(1).max(100),
  lastName: optionalText(100),
  title: optionalText(120),
  phone: optionalText(40),
  email: z
    .union([z.email(), z.literal("")])
    .optional()
    .transform((value) => value || undefined),
});

const nullableCardText = (max: number) => z.string().trim().max(max).nullable();

export const businessCardExtractionSchema = z.object({
  firstName: nullableCardText(100),
  lastName: nullableCardText(100),
  title: nullableCardText(120),
  companyName: nullableCardText(200),
  phone: nullableCardText(40),
  email: z.email().nullable(),
  website: z.url().nullable(),
  confidence: z.number().min(0).max(1),
  needsReview: z.literal(true),
});

export type BusinessCardExtraction = z.infer<
  typeof businessCardExtractionSchema
>;

export type CompanyCreate = z.infer<typeof companyCreateSchema>;
