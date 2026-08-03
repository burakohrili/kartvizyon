import { z } from "zod";

export const activityCommentCreateSchema = z.object({
  visitId: z.uuid(),
  body: z.string().trim().min(1).max(2000),
});

export const formFieldSchema = z.object({
  key: z.string().regex(/^[a-z][a-zA-Z0-9_]{1,63}$/),
  label: z.string().trim().min(2).max(120),
  type: z.enum([
    "text",
    "textarea",
    "number",
    "money",
    "date",
    "single_select",
    "multi_select",
    "boolean",
    "photo",
    "file",
    "signature",
    "location",
    "product",
    "contact",
  ]),
  required: z.boolean().default(false),
  options: z.array(z.string().trim().min(1).max(100)).max(100).optional(),
});

export const formTemplateCreateSchema = z.object({
  workspaceId: z.uuid(),
  name: z.string().trim().min(2).max(160),
  description: z.string().trim().max(500).nullable().optional(),
  fields: z.array(formFieldSchema).min(1).max(100),
});

export const formSubmissionCreateSchema = z.object({
  templateId: z.uuid(),
  companyId: z.uuid().nullable().optional(),
  visitId: z.uuid().nullable().optional(),
  data: z.record(z.string(), z.unknown()),
});

export const documentMetadataSchema = z.object({
  workspaceId: z.uuid(),
  companyId: z.uuid().nullable().optional(),
  visitId: z.uuid().nullable().optional(),
  fileName: z.string().trim().min(1).max(240),
  mimeType: z.enum([
    "application/pdf",
    "image/jpeg",
    "image/png",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  ]),
  sizeBytes: z
    .number()
    .int()
    .positive()
    .max(20 * 1024 * 1024),
  sha256: z.string().regex(/^[a-f0-9]{64}$/),
  storagePath: z.string().trim().min(3).max(500),
});
