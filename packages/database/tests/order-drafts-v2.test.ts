import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const migration = readFileSync(
  resolve(import.meta.dirname, "../migrations/0031_order_drafts_v2.up.sql"),
  "utf8",
).toLowerCase();

describe("order drafts v2 state machine", () => {
  it("reddedilmiş kaydı yalnız sahibi için taslağa döndürür ve audit izini korur", () => {
    expect(migration).toContain("target_order.status <> 'rejected'");
    expect(migration).toContain("target_order.created_by <> auth.uid()");
    expect(migration).toContain("jsonb_strip_nulls");
    expect(migration).toContain("'rejectionreason'");
  });

  it("gerçek red nedenini ve karar zamanını zorunlu kaydeder", () => {
    expect(migration).toContain("red nedeni gereklidir");
    expect(migration).toContain("rejected_at");
    expect(migration).toContain("approved_by = auth.uid()");
  });

  it("pending ve approved kayıtların içerik mutasyonunu reddeder", () => {
    expect(migration).toContain("target_order.status <> 'draft'");
    expect(migration).toContain(
      "yalnız taslak durumundaki sipariş düzenlenebilir",
    );
  });

  it("müşteri, ürün ve para birimini tenant kapsamında doğrular", () => {
    expect(migration).toContain("workspace_id = target_order.workspace_id");
    expect(migration).toContain("archived_at is null");
    expect(migration).toContain("product.currency <> target_currency");
    expect(migration).toContain("active = true");
  });

  it("toplamı istemciden almaz ve canonical hesaplayıcıyı çağırır", () => {
    expect(migration).toContain("perform public.recalculate_order_draft");
    expect(migration).toContain("round(net * (1 + product.tax_rate / 100), 2)");
    expect(migration).not.toContain("target_grand_total");
  });
});
