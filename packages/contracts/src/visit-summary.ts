import { z } from "zod";

const followUpSchema = z.object({
  title: z.string().trim().min(1).max(160),
  dueDate: z.iso.date().nullable(),
  ownerHint: z.string().trim().max(120).nullable(),
});

export const visitSummarySchema = z.object({
  summary: z.string().trim().min(10).max(1200),
  outcome: z.enum(["positive", "neutral", "negative", "unknown"]),
  customerNeeds: z.array(z.string().trim().min(1).max(240)).max(10),
  promises: z.array(z.string().trim().min(1).max(240)).max(10),
  followUps: z.array(followUpSchema).max(10),
  sensitiveContentDetected: z.boolean(),
  confidence: z.number().min(0).max(1),
});

export type VisitSummary = z.infer<typeof visitSummarySchema>;
