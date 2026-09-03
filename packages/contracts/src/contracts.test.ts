import { describe, expect, it } from "vitest";
import {
  assertSameOrganization,
  businessCardExtractionSchema,
  canTransition,
  isManagerVisible,
  visitSummarySchema,
  workspaceContextSchema,
  companyCreateSchema,
  duplicateCheckSchema,
  taskCreateSchema,
  calculateVisitPriority,
  haversineDistanceKm,
  reportFiltersSchema,
  reportShareCreateSchema,
  opportunityCreateSchema,
  orderDraftCreateSchema,
  plannedVisitCreateSchema,
  activityCommentCreateSchema,
  formTemplateCreateSchema,
  documentMetadataSchema,
  webhookCreateSchema,
  apiCredentialCreateSchema,
  privacyRequestSchema,
} from "./index";

describe("ticari entegrasyon ve KVKK sözleşmeleri", () => {
  const workspaceId = "00000000-0000-4000-8000-000000000001";
  it("webhook için HTTPS ve izinli olay ister", () => {
    expect(
      webhookCreateSchema.safeParse({
        workspaceId,
        name: "ERP",
        url: "http://example.com",
        events: ["visit.approved"],
      }).success,
    ).toBe(false);
    expect(
      webhookCreateSchema.safeParse({
        workspaceId,
        name: "ERP",
        url: "https://example.com/hook",
        events: ["visit.approved"],
      }).success,
    ).toBe(true);
  });
  it("API anahtar kapsamlarını beyaz listeyle sınırlar", () => {
    expect(
      apiCredentialCreateSchema.safeParse({
        workspaceId,
        name: "Rapor",
        scopes: ["admin:write"],
      }).success,
    ).toBe(false);
  });
  it("yalnızca dışa aktarma ve silme talebi kabul eder", () => {
    expect(
      privacyRequestSchema.safeParse({ workspaceId, kind: "export" }).success,
    ).toBe(true);
    expect(
      privacyRequestSchema.safeParse({ workspaceId, kind: "change" }).success,
    ).toBe(false);
  });
});

describe("onay akışı", () => {
  it("AI özetini doğrudan onaylı duruma geçirmez", () => {
    expect(canTransition("processing", "approved")).toBe(false);
    expect(canTransition("processing", "needs_review")).toBe(true);
  });

  it("yöneticiye yalnızca onaylı kaydı gösterir", () => {
    expect(isManagerVisible("needs_review")).toBe(false);
    expect(isManagerVisible("approved")).toBe(true);
  });
});

describe("ziyaret öncelik skoru", () => {
  it("yakın ve gecikmiş müşteriyi daha yüksek puanlar", () => {
    const urgent = calculateVisitPriority({
      daysSinceVisit: 120,
      overdueTaskCount: 2,
      customerValue: 0.8,
      distanceKm: 2,
    });
    const routine = calculateVisitPriority({
      daysSinceVisit: 10,
      overdueTaskCount: 0,
      customerValue: 0.2,
      distanceKm: 20,
    });
    expect(urgent.total).toBeGreaterThan(routine.total);
    expect(urgent.reasons.length).toBeGreaterThan(0);
  });
  it("İstanbul içi iki noktanın mesafesini hesaplar", () => {
    const distance = haversineDistanceKm(
      { latitude: 41.0082, longitude: 28.9784 },
      { latitude: 41.0256, longitude: 29.0963 },
    );
    expect(distance).toBeGreaterThan(5);
    expect(distance).toBeLessThan(15);
  });
});

describe("takip sözleşmesi", () => {
  it("boş görev başlığını reddeder", () => {
    expect(
      taskCreateSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        organizationId: null,
        companyId: null,
        visitId: null,
        title: "",
        dueAt: null,
        assignedTo: null,
      }).success,
    ).toBe(false);
  });
});

describe("çalışma alanı sözleşmesi", () => {
  it("kişisel alanda organizasyon kimliğini reddeder", () => {
    expect(
      workspaceContextSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        organizationId: crypto.randomUUID(),
        kind: "personal",
      }).success,
    ).toBe(false);
  });
});

describe("müşteri sözleşmesi", () => {
  it("hatalı e-postayı reddeder", () => {
    expect(
      companyCreateSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        organizationId: null,
        name: "Atlas",
        email: "yanlış",
      }).success,
    ).toBe(false);
  });
  it("duplicate kontrolünde kısa firma adını reddeder", () => {
    expect(
      duplicateCheckSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        name: "A",
      }).success,
    ).toBe(false);
  });
});

describe("tenant izolasyonu", () => {
  it("başka organizasyon kaynağını reddeder", () => {
    expect(() =>
      assertSameOrganization(
        { userId: "u1", workspaceId: "w1", organizationId: "o1" },
        "o2",
      ),
    ).toThrow();
  });
});

describe("AI sözleşmesi", () => {
  it("geçersiz güven skorunu reddeder", () => {
    const result = visitSummarySchema.safeParse({
      summary: "Müşteri yeni teklif için cuma gününe kadar dönüş bekliyor.",
      outcome: "positive",
      customerNeeds: [],
      promises: [],
      followUps: [],
      sensitiveContentDetected: false,
      confidence: 2,
    });
    expect(result.success).toBe(false);
  });
});

describe("kartvizit OCR sözleşmesi", () => {
  it("çıktıyı zorunlu kullanıcı incelemesi olarak işaretler", () => {
    const result = businessCardExtractionSchema.parse({
      firstName: "Ayşe",
      lastName: "Yılmaz",
      title: "Satın Alma Müdürü",
      companyName: "Örnek A.Ş.",
      phone: "+90 555 000 00 00",
      email: "ayse@example.com",
      website: "https://example.com",
      address: "Gazi Osman Paşa Mah. 5499/1 Sok. No:9 Bornova / İzmir",
      confidence: 0.91,
      needsReview: true,
    });
    expect(result.needsReview).toBe(true);
  });

  it("geçersiz e-posta ve otomatik onayı reddeder", () => {
    expect(
      businessCardExtractionSchema.safeParse({
        firstName: null,
        lastName: null,
        title: null,
        companyName: null,
        phone: null,
        email: "geçersiz",
        website: null,
        confidence: 0.5,
        needsReview: false,
      }).success,
    ).toBe(false);
  });
});

describe("rapor sözleşmesi", () => {
  it("bitişten sonraki başlangıç tarihini reddeder", () => {
    expect(
      reportFiltersSchema.safeParse({
        from: "2026-08-10",
        to: "2026-08-01",
      }).success,
    ).toBe(false);
  });

  it("güvenli bağlantı süresini 30 günle sınırlar", () => {
    expect(
      reportShareCreateSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        title: "Haftalık saha raporu",
        filters: {},
        validForHours: 721,
      }).success,
    ).toBe(false);
  });
});

describe("satış operasyonları sözleşmesi", () => {
  it("fırsat olasılığını açıklanabilir yüzdeyle sınırlar", () => {
    expect(
      opportunityCreateSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        companyId: crypto.randomUUID(),
        title: "Yeni hat yatırımı",
        probability: 120,
      }).success,
    ).toBe(false);
  });

  it("ürünsüz sipariş taslağını reddeder", () => {
    expect(
      orderDraftCreateSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        companyId: crypto.randomUUID(),
        items: [],
      }).success,
    ).toBe(false);
  });

  it("bitişi başlangıçtan önce olan ziyaret planını reddeder", () => {
    expect(
      plannedVisitCreateSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        companyId: crypto.randomUUID(),
        representativeId: crypto.randomUUID(),
        purpose: "Teknik keşif",
        plannedStartAt: "2026-08-03T12:00:00.000Z",
        plannedEndAt: "2026-08-03T11:00:00.000Z",
      }).success,
    ).toBe(false);
  });
});

describe("etkileşim ve belge sözleşmeleri", () => {
  it("boş yönetici yorumunu reddeder", () => {
    expect(
      activityCommentCreateSchema.safeParse({
        visitId: crypto.randomUUID(),
        body: " ",
      }).success,
    ).toBe(false);
  });

  it("alan anahtarı geçersiz form şablonunu reddeder", () => {
    expect(
      formTemplateCreateSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        name: "Teknik keşif",
        fields: [{ key: "Geçersiz Alan", label: "Not", type: "text" }],
      }).success,
    ).toBe(false);
  });

  it("20 MB üzerindeki belgeyi reddeder", () => {
    expect(
      documentMetadataSchema.safeParse({
        workspaceId: crypto.randomUUID(),
        fileName: "teklif.pdf",
        mimeType: "application/pdf",
        sizeBytes: 21 * 1024 * 1024,
        sha256: "a".repeat(64),
        storagePath: "owner/document.pdf",
      }).success,
    ).toBe(false);
  });
});

describe("müşteri web sitesi normalizasyonu", () => {
  // Kullanıcı "firma.com" yazdığında müşteri hiç kaydedilemiyor ve yalnız
  // "Geçersiz istek." görüyordu. Şema artık şemasız adresi tamamlar.
  const base = {
    workspaceId: "00000000-0000-4000-8000-000000000001",
    organizationId: null,
    name: "Atlas Medikal",
  };

  it("şemasız adrese https ekler", () => {
    const parsed = companyCreateSchema.parse({
      ...base,
      website: "atlasmedikal.com",
    });
    expect(parsed.website).toBe("https://atlasmedikal.com");
  });

  it("www ile başlayan adresi de tamamlar", () => {
    expect(
      companyCreateSchema.parse({ ...base, website: "www.atlasmedikal.com" })
        .website,
    ).toBe("https://www.atlasmedikal.com");
  });

  it("zaten şemalı adrese dokunmaz", () => {
    expect(
      companyCreateSchema.parse({
        ...base,
        website: "https://atlasmedikal.com",
      }).website,
    ).toBe("https://atlasmedikal.com");
  });

  it("boş alanı sorun etmez", () => {
    expect(companyCreateSchema.parse({ ...base, website: "" }).website).toBe(
      undefined,
    );
    expect(companyCreateSchema.parse(base).website).toBe(undefined);
  });

  it("gerçekten geçersiz adresi reddeder", () => {
    expect(
      companyCreateSchema.safeParse({ ...base, website: "bozuk deger" })
        .success,
    ).toBe(false);
  });
});

describe("müşteri kısa adı", () => {
  const base = {
    workspaceId: "00000000-0000-4000-8000-000000000001",
    organizationId: null,
    name: "Ohrili Makina Sanayi ve Ticaret Limited Şirketi",
  };

  it("kısa adı kırpar ve kabul eder", () => {
    expect(
      companyCreateSchema.parse({ ...base, displayName: "  Ohrili Makina  " })
        .displayName,
    ).toBe("Ohrili Makina");
  });

  it("80 karakteri aşan kısa adı reddeder", () => {
    expect(
      companyCreateSchema.safeParse({ ...base, displayName: "x".repeat(81) })
        .success,
    ).toBe(false);
  });
});
