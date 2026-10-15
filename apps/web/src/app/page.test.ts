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
const englishPage = readFileSync(
  new URL("./marketing-home-en.tsx", import.meta.url),
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

  it("resmî iOS ve Android indirme sayfalarına bağlantı verir", () => {
    expect(page).toContain(
      "https://apps.apple.com/tr/app/kartvizyon-ai/id6797552440",
    );
    expect(page).toContain(
      "https://play.google.com/store/apps/details?id=app.kartvizyon.mobile",
    );
  });

  it("temsili ses notunu transkript ve AI taslağı olarak ayırır", () => {
    expect(page).toContain("müşteri ile görüştüm");
    expect(page).toContain("ses tanıma metni");
    expect(page).toContain("ai görüşme özeti");
    expect(page).toContain("gerçek kayıt değil");
  });

  it("English landing page keeps purchase and AI-review claims accurate", () => {
    expect(page).toContain("getrequestlocale");
    expect(page).toContain("marketinghomeenglish");
    expect(englishPage).toContain('lang="en"');
    expect(englishPage).toContain("not added to the customer record");
    expect(englishPage).toContain("approves it.");
    expect(englishPage).toContain("while it is active");
    expect(englishPage).toContain("₺449/month including vat");
    expect(englishPage).toContain("store availability and purchase terms");
    expect(englishPage).toContain("https://apps.apple.com/app/id6797552440");
    expect(englishPage).toContain(
      "play.google.com/store/apps/details?id=app.kartvizyon.mobile",
    );
  });
});
