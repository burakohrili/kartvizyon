import { z } from "zod";

export const webhookCreateSchema = z.object({
  workspaceId: z.uuid(),
  name: z.string().trim().min(2).max(120),
  url: z.url().refine((value) => value.startsWith("https://"), "HTTPS gerekli"),
  events: z
    .array(z.enum(["visit.approved", "task.completed", "order.approved"]))
    .min(1),
});

export const apiCredentialCreateSchema = z.object({
  workspaceId: z.uuid(),
  name: z.string().trim().min(2).max(120),
  scopes: z
    .array(z.enum(["customers:read", "visits:read", "reports:read"]))
    .min(1),
});

export const privacyRequestSchema = z.object({
  workspaceId: z.uuid(),
  kind: z.enum(["export", "deletion"]),
  reason: z.string().trim().max(1000).optional(),
});

export const consentUpdateSchema = z.object({
  workspaceId: z.uuid(),
  purpose: z.enum([
    "product_analytics",
    "ai_processing",
    "email_notifications",
  ]),
  granted: z.boolean(),
});

export type WebhookCreate = z.infer<typeof webhookCreateSchema>;
export type ApiCredentialCreate = z.infer<typeof apiCredentialCreateSchema>;
