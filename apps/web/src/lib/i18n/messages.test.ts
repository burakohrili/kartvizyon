import { describe, expect, it } from "vitest";
import { getMessages } from "./messages";
import { getDemoRecords } from "./demo-records";

function sortedKeys(value: object) {
  return Object.keys(value).sort();
}

function messageShape(value: unknown, prefix = ""): string[] {
  if (Array.isArray(value)) {
    return value.flatMap((item, index) =>
      messageShape(item, `${prefix}[${index}]`),
    );
  }
  if (value && typeof value === "object") {
    return Object.entries(value).flatMap(([key, child]) =>
      messageShape(child, prefix ? `${prefix}.${key}` : key),
    );
  }
  return [prefix];
}

describe("web localization messages", () => {
  it("localizes fictional demo records without changing the Turkish catalog", () => {
    expect(getDemoRecords("en").companies[0]).toBe("Atlas Medical");
    expect(getDemoRecords("en").tasks[0]).toBe("Send the revised proposal");
    expect(getDemoRecords("tr").companies[0]).toBe("Atlas Medikal");
    expect(getDemoRecords("tr").tasks[0]).toBe("Revize teklifi gönder");
  });

  it("keeps every nested EN/TR catalog key and array slot aligned", () => {
    expect(messageShape(getMessages("en"))).toEqual(
      messageShape(getMessages("tr")),
    );
  });

  it("keeps Turkish and English message structures in parity", () => {
    const tr = getMessages("tr");
    const en = getMessages("en");
    expect(sortedKeys(en)).toEqual(sortedKeys(tr));
    expect(sortedKeys(en.dashboard)).toEqual(sortedKeys(tr.dashboard));
    expect(sortedKeys(en.customers)).toEqual(sortedKeys(tr.customers));
    expect(sortedKeys(en.tasks)).toEqual(sortedKeys(tr.tasks));
    expect(sortedKeys(en.visits)).toEqual(sortedKeys(tr.visits));
    expect(sortedKeys(en.customerDetail)).toEqual(
      sortedKeys(tr.customerDetail),
    );
    expect(sortedKeys(en.review)).toEqual(sortedKeys(tr.review));
    expect(sortedKeys(en.debrief)).toEqual(sortedKeys(tr.debrief));
    expect(sortedKeys(en.map)).toEqual(sortedKeys(tr.map));
    expect(sortedKeys(en.activity)).toEqual(sortedKeys(tr.activity));
    expect(sortedKeys(en.notifications)).toEqual(sortedKeys(tr.notifications));
    expect(sortedKeys(en.calendar)).toEqual(sortedKeys(tr.calendar));
    expect(sortedKeys(en.operations)).toEqual(sortedKeys(tr.operations));
    expect(sortedKeys(en.reports)).toEqual(sortedKeys(tr.reports));
    expect(sortedKeys(en.sharedReport)).toEqual(sortedKeys(tr.sharedReport));
    expect(sortedKeys(en.workspaceAdmin)).toEqual(
      sortedKeys(tr.workspaceAdmin),
    );
    expect(sortedKeys(en.auth)).toEqual(sortedKeys(tr.auth));
    expect(sortedKeys(en.auth.errors)).toEqual(sortedKeys(tr.auth.errors));
    expect(sortedKeys(en.import)).toEqual(sortedKeys(tr.import));
    expect(sortedKeys(en.import.fields)).toEqual(sortedKeys(tr.import.fields));
    expect(sortedKeys(en.offline)).toEqual(sortedKeys(tr.offline));
    expect(sortedKeys(en.customerForms)).toEqual(sortedKeys(tr.customerForms));
    expect(sortedKeys(en.customerForms.errors)).toEqual(
      sortedKeys(tr.customerForms.errors),
    );
    expect(sortedKeys(en.settings)).toEqual(sortedKeys(tr.settings));
    expect(sortedKeys(en.settings.billing)).toEqual(
      sortedKeys(tr.settings.billing),
    );
    expect(sortedKeys(en.settings.integrations)).toEqual(
      sortedKeys(tr.settings.integrations),
    );
    expect(sortedKeys(en.settings.privacy)).toEqual(
      sortedKeys(tr.settings.privacy),
    );
    expect(sortedKeys(en.settings.privacy.statuses)).toEqual(
      sortedKeys(tr.settings.privacy.statuses),
    );
  });

  it("provides distinct language and dashboard copy for both locales", () => {
    expect(getMessages("en").dashboard.overview).toBe("Overview");
    expect(getMessages("tr").dashboard.overview).toBe("Genel Bakış");
    expect(getMessages("en").switchLanguage).toBe("Switch language");
    expect(getMessages("tr").switchLanguage).toBe("Dili değiştir");
  });

  it("localizes app-shell offline and error recovery states", () => {
    const en = getMessages("en");
    const tr = getMessages("tr");
    expect(en.offlineStatus.queued(2)).toBe("2 visit notes waiting to sync");
    expect(tr.offlineStatus.queued(1)).toBe(
      "1 ziyaret notu senkronizasyon bekliyor",
    );
    expect(en.offlineStatus.offline(1)).toContain("saved on this device");
    expect(tr.offlineStatus.offline(0)).toBe("Çevrimdışısınız");
    expect(en.errorPage.retry).toBe("Try again");
    expect(tr.errorPage.retry).toBe("Tekrar dene");
    expect(en.languageSaveFailed).not.toBe(tr.languageSaveFailed);
  });

  it("localizes sales, product, and order workflows without translating data fields", () => {
    const en = getMessages("en").operations;
    const tr = getMessages("tr").operations;
    expect(en.opportunitiesTitle).toBe("Opportunities");
    expect(tr.opportunitiesTitle).toBe("Fırsatlar");
    expect(en.stageWon).toBe("Won");
    expect(tr.stageWon).toBe("Kazanıldı");
    expect(en.statusPending).toBe("Pending approval");
    expect(tr.statusPending).toBe("Onay bekliyor");
    expect(en.priceListRequirements).toContain("20 MB");
    expect(tr.priceListRequirements).toContain("20 MB");
    expect(en.uploadDocument).toBe("Upload document");
    expect(tr.uploadDocument).toBe("Belge yükle");
    expect(en.formTemplate).toBe("Form template");
    expect(tr.formTemplate).toBe("Form şablonu");
  });

  it("localizes report sharing and privacy disclosures", () => {
    expect(getMessages("en").reports.secureLink).toBe("7-day secure link");
    expect(getMessages("tr").reports.secureLink).toBe(
      "7 günlük güvenli bağlantı",
    );
    expect(getMessages("en").reports.privacy).toContain("raw audio");
    expect(getMessages("tr").reports.privacy).toContain("ham ses");
  });

  it("localizes public shared-report chrome without rewriting report content", () => {
    const en = getMessages("en").sharedReport;
    const tr = getMessages("tr").sharedReport;
    expect(en.approvedVisit).toBe("Approved visits");
    expect(tr.approvedVisit).toBe("Onaylı ziyaret");
    expect(en.expires("Oct 14, 2026, 3:00 PM")).toContain("This link");
    expect(tr.expires("14 Eki 2026 15:00")).toContain("Bağlantı");
  });

  it("localizes sign-in, invitation, import, and offline recovery flows", () => {
    expect(getMessages("en").auth.welcomeTitle).toBe("Welcome back");
    expect(getMessages("tr").auth.welcomeTitle).toBe("Tekrar hoş geldiniz");
    expect(getMessages("en").auth.errors.credentials).toContain("password");
    expect(getMessages("tr").auth.errors.credentials).toContain("şifre");
    expect(getMessages("en").import.startImport).toBe("Start import");
    expect(getMessages("tr").import.startImport).toBe("İçe aktarmayı başlat");
    expect(getMessages("en").offline.title).toBe("You are currently offline");
    expect(getMessages("tr").offline.title).toBe("Bağlantı şu anda yok");
    expect(getMessages("en").customerForms.scanReady).toContain(
      "review before saving",
    );
    expect(getMessages("tr").customerForms.scanReady).toContain("kontrol edin");
    expect(getMessages("en").settings.privacy.statuses.ready).toBe("Ready");
    expect(getMessages("tr").settings.privacy.statuses.ready).toBe("Hazır");
  });
});
