import { z } from "zod";

const optionalText = (max: number) =>
  z
    .string()
    .trim()
    .max(max)
    .optional()
    .transform((value) => value || undefined);

/**
 * Kullanıcı "firma.com" yazdığında şema bunu reddediyordu ve müşteri hiç
 * kaydedilemiyordu. Kartvizit OCR yolu şemayı çağırmadan önce zaten
 * `https://` deneyerek bu düzeltmeyi yapıyordu; manuel giriş yapmıyordu.
 * Normalizasyon şemaya alınarak her iki yol da aynı davranışı gösterir.
 */
const optionalWebsite = z
  .string()
  .trim()
  .max(300)
  .optional()
  .transform((value) => {
    if (!value) return undefined;
    return /^[a-z][a-z0-9+.-]*:\/\//i.test(value) ? value : `https://${value}`;
  })
  .refine((value) => value === undefined || z.url().safeParse(value).success, {
    message: "Geçerli bir web adresi girin (örnek: firma.com)",
  });

export const companyCreateSchema = z.object({
  workspaceId: z.uuid(),
  organizationId: z.uuid().nullable(),
  name: z.string().trim().min(2).max(200),
  displayName: optionalText(80),
  phone: optionalText(40),
  email: z
    .union([z.email(), z.literal("")])
    .optional()
    .transform((value) => value || undefined),
  website: optionalWebsite,
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
  // `companyCreateSchema.address` ile aynı sınır. Adres yalnız görüntü için
  // değil: müşteri kaydı bunu koordinata çeviriyor ve koordinatsız müşteri
  // yakınlık hatırlatmalarına hiç girmiyor.
  address: nullableCardText(500),
  confidence: z.number().min(0).max(1),
  needsReview: z.literal(true),
});

export type BusinessCardExtraction = z.infer<
  typeof businessCardExtractionSchema
>;

export type CompanyCreate = z.infer<typeof companyCreateSchema>;
