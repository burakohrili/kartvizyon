import { readFileSync, readdirSync } from "node:fs";
import { dirname, join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

/**
 * Oturumsuz ziyaretçi hiçbir uygulama sayfasında uyarısız kalmamalı.
 *
 * 19 Ağustos 2026 denetimi: `app.kartvizyon.app` altındaki korumalı sayfaların
 * hepsi çerezsiz istekte 200 dönüyor ve demo içerikle doluyordu. Bir kısmında
 * `demo-notice` kutusu vardı, `settings/team` gibi bazılarında hiçbir uyarı
 * yoktu ve hiçbirinde giriş bağlantısı yoktu. Uyarıyı her sayfanın kendi
 * kararına bırakmak bu duruma zaten bir kez yol açtığı için burada zorunlu
 * tutuluyor: yeni bir uygulama sayfası eklendiğinde bu test onu yakalar.
 */
const appDirectory = dirname(fileURLToPath(import.meta.url));

/** Oturum gerektirmeyen, herkese açık yüzey. Şerit buralara ait değildir. */
const publicRoutes = new Set([
  "", // pazarlama ana sayfası
  "about",
  "account-deletion",
  "contact",
  "delivery-refund",
  "distance-sales",
  "invite/[token]",
  "kvkk",
  "login",
  "privacy",
  "share/reports/[token]",
  "support",
  "terms",
  // Çevrimdışı yedek sayfası; ağ yokken oturum çözülemez.
  "offline",
]);

function pageRoutes(directory: string): string[] {
  const found: string[] = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "api") continue;
      found.push(...pageRoutes(path));
    } else if (entry.name === "page.tsx") {
      found.push(relative(appDirectory, directory).split(sep).join("/"));
    }
  }
  return found;
}

describe("demo şeridi", () => {
  const routes = pageRoutes(appDirectory).filter(
    (route) => !publicRoutes.has(route),
  );

  it("uygulama sayfalarını bulur", () => {
    expect(routes.length).toBeGreaterThan(20);
  });

  it("her uygulama sayfası şeridi basar", () => {
    const missing = routes.filter(
      (route) =>
        !readFileSync(join(appDirectory, route, "page.tsx"), "utf8").includes(
          "<DemoBanner />",
        ),
    );
    expect(missing, `şerit eksik: ${missing.join(", ")}`).toEqual([]);
  });

  it("şerit oturum varken hiçbir şey basmaz ve girişe götürür", () => {
    const source = readFileSync(join(appDirectory, "demo-banner.tsx"), "utf8");
    expect(source).toContain("if (user) return null");
    expect(source).toContain('href="/login"');
  });
});
