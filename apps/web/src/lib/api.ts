import { ZodError } from "zod";

/** Doğrulama hatasında kullanıcıya hangi alanı düzelteceğini söylemek için. */
const FIELD_LABELS: Record<string, string> = {
  name: "firma adı",
  firstName: "ad",
  lastName: "soyad",
  title: "unvan",
  phone: "telefon",
  email: "e-posta",
  website: "web sitesi",
  address: "adres",
  workspaceId: "çalışma alanı",
  organizationId: "organizasyon",
  companyId: "firma",
};

export function apiError(error: unknown): Response {
  if (error instanceof ZodError) {
    // "Geçersiz istek." tek başına kullanıcıya hangi alanı düzelteceğini
    // söylemiyordu; hatalı alanı ada göre bildir.
    const fields = [
      ...new Set(
        error.issues
          .map((issue) => String(issue.path.at(-1) ?? ""))
          .filter(Boolean)
          .map((key) => FIELD_LABELS[key] ?? key),
      ),
    ];
    const detail = fields.length ? ` Kontrol edin: ${fields.join(", ")}.` : "";
    return Response.json(
      { error: `Geçersiz istek.${detail}`, issues: error.issues },
      { status: 400 },
    );
  }
  console.error(error);
  return Response.json({ error: "İşlem tamamlanamadı." }, { status: 500 });
}

export function serviceUnavailable(): Response {
  return Response.json(
    { error: "Supabase bağlantısı henüz yapılandırılmadı." },
    { status: 503 },
  );
}
