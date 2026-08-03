export function GET(request: Request) {
  const origin = new URL(request.url).origin;
  return Response.json({
    openapi: "3.1.0",
    info: {
      title: "KartVizyon AI API",
      version: "0.1.0",
      description: "Saha müşteri hafızası ve ziyaret yönetimi API'si",
    },
    servers: [{ url: origin }],
    components: {
      securitySchemes: {
        bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT" },
      },
    },
    security: [{ bearerAuth: [] }],
    paths: {
      "/api/customers": {
        get: {
          summary: "Müşterileri listeler",
          responses: { "200": { description: "Başarılı" } },
        },
      },
      "/api/visits": {
        get: {
          summary: "Ziyaretleri listeler",
          responses: { "200": { description: "Başarılı" } },
        },
        post: {
          summary: "Taslak ziyaret oluşturur",
          responses: { "201": { description: "Oluşturuldu" } },
        },
      },
      "/api/tasks": {
        get: {
          summary: "Görevleri listeler",
          responses: { "200": { description: "Başarılı" } },
        },
        patch: {
          summary: "Görev durumunu değiştirir",
          responses: { "200": { description: "Başarılı" } },
        },
      },
      "/api/reports/export/{format}": {
        get: {
          summary: "Onaylı ziyaret raporunu dışa aktarır",
          parameters: [
            {
              name: "format",
              in: "path",
              required: true,
              schema: { type: "string", enum: ["pdf", "xlsx"] },
            },
          ],
          responses: { "200": { description: "Dosya" } },
        },
      },
      "/api/health": {
        get: {
          security: [],
          summary: "Servis sağlığı",
          responses: { "200": { description: "Sağlıklı" } },
        },
      },
    },
  });
}
