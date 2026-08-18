import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const migrationPath = resolve(
  import.meta.dirname,
  "../migrations/0001_foundation.up.sql",
);
const sql = await readFile(migrationPath, "utf8");
const memorySql = await readFile(
  resolve(import.meta.dirname, "../migrations/0004_memory_briefing.up.sql"),
  "utf8",
);
const importSql = await readFile(
  resolve(import.meta.dirname, "../migrations/0005_import_jobs.up.sql"),
  "utf8",
);
const geofenceSql = await readFile(
  resolve(import.meta.dirname, "../migrations/0006_geofence_events.up.sql"),
  "utf8",
);
const invitationSql = await readFile(
  resolve(import.meta.dirname, "../migrations/0007_secure_invitations.up.sql"),
  "utf8",
);
const voiceAiSql = await readFile(
  resolve(import.meta.dirname, "../migrations/0008_voice_ai.up.sql"),
  "utf8",
);
const debriefIdempotencySql = await readFile(
  resolve(import.meta.dirname, "../migrations/0009_debrief_idempotency.up.sql"),
  "utf8",
);
const visitAuditSql = await readFile(
  resolve(
    import.meta.dirname,
    "../migrations/0010_visit_audit_retention.up.sql",
  ),
  "utf8",
);
const approvedTasksSql = await readFile(
  resolve(
    import.meta.dirname,
    "../migrations/0011_approved_follow_up_tasks.up.sql",
  ),
  "utf8",
);
const sessionSecuritySql = await readFile(
  resolve(
    import.meta.dirname,
    "../migrations/0012_session_security_audit.up.sql",
  ),
  "utf8",
);
const reportShareSql = await readFile(
  resolve(
    import.meta.dirname,
    "../migrations/0013_secure_report_shares.up.sql",
  ),
  "utf8",
);
const salesOperationsSql = await readFile(
  resolve(import.meta.dirname, "../migrations/0014_sales_operations.up.sql"),
  "utf8",
);
const interactionsSql = await readFile(
  resolve(
    import.meta.dirname,
    "../migrations/0015_interactions_documents_forms.up.sql",
  ),
  "utf8",
);
const commercialSql = await readFile(
  resolve(
    import.meta.dirname,
    "../migrations/0016_commercial_integrations_privacy.up.sql",
  ),
  "utf8",
);
const operationalSecuritySql = await readFile(
  resolve(
    import.meta.dirname,
    "../migrations/0017_operational_security.up.sql",
  ),
  "utf8",
);
const documentScanJobsSql = await readFile(
  resolve(import.meta.dirname, "../migrations/0018_document_scan_jobs.up.sql"),
  "utf8",
);
const entitlementsSql = await readFile(
  resolve(import.meta.dirname, "../migrations/0021_entitlements.up.sql"),
  "utf8",
);
const entitlementsDownSql = await readFile(
  resolve(import.meta.dirname, "../migrations/0021_entitlements.down.sql"),
  "utf8",
);
const locationSourceSql = await readFile(
  resolve(
    import.meta.dirname,
    "../migrations/0022_company_location_source.up.sql",
  ),
  "utf8",
);

describe("temel veri güvenliği", () => {
  it.each([
    "organizations",
    "workspaces",
    "memberships",
    "companies",
    "contacts",
    "visits",
    "tasks",
    "customer_memory_cards",
    "audit_logs",
  ])("%s tablosunda RLS açar", (table) =>
    expect(sql).toMatch(
      new RegExp(
        `alter table public\\.${table} enable row level security`,
        "i",
      ),
    ),
  );

  it("kurumsal erişimi üyelik fonksiyonuyla sınırlar", () => {
    expect(sql).toContain("public.is_organization_member(organization_id)");
  });

  it("yönetici akışını yalnızca onaylı ziyaretlerle sınırlar", () => {
    expect(sql).toContain("status = 'approved'");
  });
});

describe("sesli AI akışı", () => {
  it.each([
    "visit_audio_assets",
    "visit_transcripts",
    "ai_jobs",
    "usage_records",
  ])("%s tablosunda RLS açar", (table) =>
    expect(voiceAiSql).toContain(
      `alter table public.${table} enable row level security`,
    ),
  );

  it("ham ses ve transkripti yalnızca sahibine açar", () => {
    expect(voiceAiSql).toContain("visit_audio_owner_only");
    expect(voiceAiSql).toContain("visit_transcript_owner_only");
    expect(voiceAiSql).toContain("owner_id = auth.uid()");
  });

  it("AI kullanımını ölçer", () => {
    expect(voiceAiSql).toContain("audio_seconds");
    expect(voiceAiSql).toContain("input_tokens");
    expect(voiceAiSql).toContain("output_tokens");
  });
});

describe("çevrimdışı debrief tekrar güvenliği", () => {
  it("istemci mutation anahtarını kullanıcı başına benzersiz tutar", () => {
    expect(debriefIdempotencySql).toContain(
      "unique (user_id, client_mutation_id)",
    );
  });
  it("kuyruk sonucunu tenant RLS ile korur", () => {
    expect(debriefIdempotencySql).toContain(
      "alter table public.debrief_submissions enable row level security",
    );
    expect(debriefIdempotencySql).toContain("user_id = auth.uid()");
  });
});

describe("ziyaret audit izi", () => {
  it.each(["visit.ai_ready", "visit.approved", "visit.returned_to_draft"])(
    "%s olayını kaydeder",
    (event) => expect(visitAuditSql).toContain(event),
  );
  it("ham transkript veya ses yolunu audit metadata'ya yazmaz", () => {
    expect(visitAuditSql).not.toContain("transcript");
    expect(visitAuditSql).not.toContain("storage_path");
  });
});

describe("onaylı AI takip görevleri", () => {
  it("yalnızca approved geçişinde görev üretir", () => {
    expect(approvedTasksSql).toContain("new.status <> 'approved'");
    expect(approvedTasksSql).toContain("old.status = 'approved'");
  });
  it("aynı takip için ikinci görev oluşturmaz", () => {
    expect(approvedTasksSql).toContain("tasks_ai_follow_up_unique");
    expect(approvedTasksSql).toContain(
      "on conflict (visit_id, source_follow_up_index)",
    );
  });
  it("seçili followUps listesini kaynak kabul eder", () => {
    expect(approvedTasksSql).toContain("new.ai_summary -> 'followUps'");
  });
});

describe("oturum güvenliği audit izi", () => {
  it("global oturum iptalini kullanıcı adına kaydeder", () => {
    expect(sessionSecuritySql).toContain("session.revoked_all");
    expect(sessionSecuritySql).toContain("auth.uid()");
    expect(sessionSecuritySql).toContain("'scope', 'global'");
  });
});

describe("müşteri hafıza kartı", () => {
  it("yalnızca onaylı ziyaretleri kaynak kabul eder", () => {
    expect(
      memorySql.match(/status = 'approved'/g)?.length,
    ).toBeGreaterThanOrEqual(2);
  });
  it("ziyaret onaylandığında hafıza kartını yeniler", () => {
    expect(memorySql).toContain("visit_approved_refresh_memory");
  });
});

describe("veri içe aktarma", () => {
  it("import işlerini tenant RLS ile korur", () => {
    expect(importSql).toContain(
      "alter table public.import_jobs enable row level security",
    );
    expect(importSql).toContain("public.can_access_workspace(workspace_id)");
  });
  it("aynı dosyanın çalışma alanına tekrar yüklenmesini engeller", () => {
    expect(importSql).toContain("unique (workspace_id, file_hash)");
  });
});

describe("geofence gizliliği", () => {
  it("olayları kullanıcı ve çalışma alanına göre izole eder", () => {
    expect(geofenceSql).toContain("user_id = auth.uid()");
    expect(geofenceSql).toContain("public.can_access_workspace(workspace_id)");
  });
  it("sürekli konum koordinatı saklamaz", () => {
    expect(geofenceSql).not.toMatch(/latitude|longitude/);
  });
});

describe("güvenli davet", () => {
  it("davet tokenını SHA-256 hash olarak saklar", () => {
    expect(invitationSql).toContain("digest(raw_token, 'sha256')");
  });
  it("yalnızca yetkili rollere davet izni verir", () => {
    expect(invitationSql).toContain("array['owner', 'sales_director']");
  });
  it("oluşturma ve iptali audit loga yazar", () => {
    expect(invitationSql).toContain("invitation.created");
    expect(invitationSql).toContain("invitation.revoked");
  });
});

describe("güvenli rapor paylaşımı", () => {
  it("ham token yerine SHA-256 özetini saklar", () => {
    expect(reportShareSql).toContain("digest(raw_token, 'sha256')");
    expect(reportShareSql).toContain("token_hash text not null unique");
  });

  it("süre, iptal ve yalnızca onaylı kaynak kurallarını uygular", () => {
    expect(reportShareSql).toContain("expires_at > now()");
    expect(reportShareSql).toContain("revoked_at is null");
    expect(reportShareSql).toContain("v.status = 'approved'");
  });

  it("paylaşım, iptal ve dışa aktarmayı audit loga yazar", () => {
    expect(reportShareSql).toContain("report.shared");
    expect(reportShareSql).toContain("report.share_revoked");
    expect(reportShareSql).toContain("report.exported");
  });
});

describe("satış operasyonları", () => {
  it.each([
    "regions",
    "teams",
    "opportunities",
    "products",
    "price_lists",
    "order_drafts",
  ])("%s tablosunu tenant RLS ile korur", (table) => {
    expect(salesOperationsSql).toContain(
      `alter table public.${table} enable row level security`,
    );
  });

  it("sipariş tutarını sunucuda yeniden hesaplar", () => {
    expect(salesOperationsSql).toContain("recalculate_order_draft");
    expect(salesOperationsSql).toContain("discount_total");
    expect(salesOperationsSql).toContain("tax_total");
  });

  it("sipariş onayını yönetici rolleriyle sınırlar ve denetler", () => {
    expect(salesOperationsSql).toContain(
      "array['owner', 'sales_director', 'regional_manager']",
    );
    expect(salesOperationsSql).toContain("'order.' || target_status::text");
  });
});

describe("yorum, bildirim, belge ve formlar", () => {
  it.each([
    "activity_comments",
    "notifications",
    "documents",
    "form_templates",
    "form_submissions",
  ])("%s tablosunda RLS açar", (table) => {
    expect(interactionsSql).toContain(
      `alter table public.${table} enable row level security`,
    );
  });

  it("yorumları yalnızca onaylı ziyaretlere ekler ve bildirim üretir", () => {
    expect(interactionsSql).toContain("status = 'approved'");
    expect(interactionsSql).toContain("manager_comment");
  });

  it("belgeleri temiz tarama olmadan erişime açmaz", () => {
    expect(interactionsSql).toContain("document-quarantine");
    expect(interactionsSql).toContain("d.scan_status = 'clean'");
  });
});

describe("ticari entegrasyonlar ve KVKK", () => {
  it.each([
    "workspace_subscriptions",
    "api_credentials",
    "webhook_endpoints",
    "user_consents",
    "privacy_requests",
  ])("%s tablosunda RLS açar", (table) => {
    expect(commercialSql).toContain(
      `alter table public.${table} enable row level security`,
    );
  });
  it("entegrasyon sırlarını düz metin yerine hash olarak saklar", () => {
    expect(commercialSql).toContain("token_hash text not null unique");
    expect(commercialSql).toContain("signing_secret_hash text not null");
    expect(commercialSql).toContain("signing_secret_ciphertext text not null");
  });
  it("kişisel veri taleplerini kullanıcıya izole eder", () => {
    expect(commercialSql).toContain("privacy_owner_all");
    expect(commercialSql).toContain("user_id = auth.uid()");
  });
});

describe("operasyonel güvenlik", () => {
  it("API isteklerini kullanıcı ve rota bazında sınırlar", () => {
    expect(operationalSecuritySql).toContain("consume_api_rate_limit");
    expect(operationalSecuritySql).toContain(
      "primary key (user_id, route_key)",
    );
  });
  it.each(["visit.approved", "task.completed", "order.approved"])(
    "%s webhook olayını kuyruğa alır",
    (event) => {
      expect(operationalSecuritySql).toContain(event);
    },
  );
  it("webhook teslimatına güvenli olay gövdesi ve ortak event kimliği ekler", () => {
    expect(operationalSecuritySql).toContain(
      "event_payload := jsonb_build_object",
    );
    expect(operationalSecuritySql).toContain("resource_id, payload");
  });
});

describe("belge zararlı yazılım tarama kuyruğu", () => {
  it("işleri eşzamanlı çalışanlar arasında atomik olarak sahiplenir", () => {
    expect(documentScanJobsSql).toContain("for update skip locked");
    expect(documentScanJobsSql).toContain("claim_document_scan_jobs");
  });

  it("takılan işleri yeniden dener ve üç denemeden sonra kapatır", () => {
    expect(documentScanJobsSql).toContain("interval '15 minutes'");
    expect(documentScanJobsSql).toContain("scan_attempts >= 3");
  });

  it("kuyruk fonksiyonunu yalnız servis rolüne açar", () => {
    expect(documentScanJobsSql).toContain(
      "grant execute on function public.claim_document_scan_jobs(integer) to service_role",
    );
  });
});

describe("plan hakları ve kota", () => {
  it("ADR-0005 plan fiyatlarını tohumlar", () => {
    expect(entitlementsSql).toContain("'individual', 'Bireysel', 349");
    expect(entitlementsSql).toContain("'team', 'Ekip', 279");
    expect(entitlementsSql).toContain("monthly_price_try = 449");
  });

  it("eski sabit fiyatlı planları kapatır ama satırlarını korur", () => {
    expect(entitlementsSql).toContain(
      "update public.subscription_plans set active = false where id in ('starter', 'growth')",
    );
    expect(entitlementsSql).not.toContain(
      "delete from public.subscription_plans where id in ('starter'",
    );
  });

  it("sınırsız limitleri null ile ifade eder", () => {
    expect(entitlementsSql).toContain(
      "max_companies is null or max_companies >= 0",
    );
    expect(entitlementsSql).toContain("max_ocr is null or max_ocr >= 0");
  });

  it("OCR tüketimini ölçülebilir metrik olarak ekler", () => {
    expect(entitlementsSql).toContain(
      "check (metric in ('audio_seconds', 'input_tokens', 'output_tokens', 'storage_bytes', 'ocr'))",
    );
  });

  it("koltuk limitini security definer fonksiyonunda uygular", () => {
    // API katmanındaki kontrol anon anahtarla doğrudan RPC çağrısıyla
    // atlatılabilirdi; kapı veritabanında olmalıdır.
    expect(entitlementsSql).toContain(
      "create or replace function public.accept_invitation",
    );
    expect(entitlementsSql).toContain("Koltuk sayısı doldu");
    expect(entitlementsSql).toContain("least(ws.seat_quantity, sp.seat_limit)");
  });

  it("mevcut üyenin daveti yeniden kabul etmesini koltuk saymaz", () => {
    expect(entitlementsSql).toContain("already_member");
  });

  it("ek AI paketi kredisini istemci yazımına kapatır", () => {
    expect(entitlementsSql).toContain(
      "create policy topups_admin_no_client_write on public.workspace_ai_topups",
    );
    expect(entitlementsSql).toContain(
      "for all using (false) with check (false)",
    );
  });

  it("ek paket satın almasını sağlayıcı referansıyla idempotent tutar", () => {
    expect(entitlementsSql).toContain(
      "create unique index workspace_ai_topups_provider_reference_idx",
    );
  });

  it("rollback koltuk kontrolsüz fonksiyonu geri yükler", () => {
    expect(entitlementsDownSql).toContain(
      "create or replace function public.accept_invitation",
    );
    expect(entitlementsDownSql).not.toContain("Koltuk sayısı doldu");
    expect(entitlementsDownSql).toContain(
      "drop table if exists public.workspace_ai_topups",
    );
  });
});

describe("müşteri konum kaynağı", () => {
  it("konumun nereden geldiğini ayırt eder", () => {
    expect(locationSourceSql).toContain("location_source");
    expect(locationSourceSql).toContain("in ('geocoded', 'pinned')");
  });

  it("mevcut koordinatlı kayıtları tahmin olarak işaretler", () => {
    // Sahada sabitlenmiş sayılırsa kullanıcı yanlış bilgi görür.
    expect(locationSourceSql).toContain("set location_source = 'geocoded'");
  });

  it("yakınlık sorgusunu hızlandıran kısmi indeks ekler", () => {
    expect(locationSourceSql).toContain("companies_workspace_location_idx");
    expect(locationSourceSql).toContain(
      "where latitude is not null and longitude is not null",
    );
  });
});
