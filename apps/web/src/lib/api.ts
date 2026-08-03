import { ZodError } from "zod";

export function apiError(error: unknown): Response {
  if (error instanceof ZodError) {
    return Response.json(
      { error: "Geçersiz istek.", issues: error.issues },
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
