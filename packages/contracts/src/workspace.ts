import { z } from "zod";
import { roleSchema } from "./permissions";

export const workspaceKindSchema = z.enum(["personal", "organization"]);

export const invitationSchema = z.object({
  email: z.email().transform((email) => email.toLocaleLowerCase("tr-TR")),
  role: roleSchema,
  expiresAt: z.iso.datetime(),
});

export const workspaceContextSchema = z
  .object({
    workspaceId: z.uuid(),
    organizationId: z.uuid().nullable(),
    kind: workspaceKindSchema,
  })
  .refine(
    ({ kind, organizationId }) =>
      kind === "organization"
        ? organizationId !== null
        : organizationId === null,
    "Çalışma alanı türü ve organizasyon bağlamı uyuşmuyor.",
  );
