import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

/**
 * Pazarlama sayfası koda karşı doğru kalmalı.
 *
 * Aynı hata iki kez yapıldı: saha modu eklendikten sonra hem mağaza
 * dokümanlarında hem sitede "arka planda konum alınmaz" ifadesi kaldı. Saha
 * modu açıkken konum arka planda da okunuyor; doğru sınır sürekli ve gizli
 * takip yapılmamasıdır (ADR-0006). Bu test üçüncü kez olmasını engeller.
 */
const page = readFileSync(
  new URL("./page.tsx", import.meta.url),
  "utf8",
).toLowerCase();

describe("pazarlama sayfası iddiaları", () => {
  it("arka planda hiç konum alınmadığını iddia etmez", () => {
    const forbidden = [
      "arka planda konumunuzu izlemediği",
      "arka planda sürekli gps takibi yapılmaz",
      "arka plan konumu kullanılmaz",
    ];
    const found = forbidden.filter((phrase) => page.includes(phrase));
    expect(
      found,
      "saha modu arka planda konum alıyor; bu ifadeler yanlış",
    ).toEqual([]);
  });

  it("saha modunu ve görünürlüğünü anlatır", () => {
    expect(page).toContain("saha modu");
    // Kullanıcı, modun çalıştığını göreceğini ve kendiliğinden kapanacağını
    // sayfadan öğrenebilmeli; izin isteminin gerekçesi budur.
    expect(page).toContain("kendiliğinden kapan");
  });

  it("AI çıktısının onaysız kayda geçmediğini söylemeye devam eder", () => {
    expect(page).toContain("onaylamadan");
  });

  it("belgenin temiz tarama olmadan açılmadığını söyler", () => {
    expect(page).toContain("temiz");
  });
});
