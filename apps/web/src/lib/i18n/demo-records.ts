import type { AppLocale } from "./locale";

/** Localized fictional records used only when the application is in demo mode. */
export function getDemoRecords(locale: AppLocale) {
  if (locale === "en") {
    return {
      companies: ["Atlas Medical", "Nova Automation", "Marmara Packaging"],
      areas: ["Sisli, Istanbul", "Umraniye, Istanbul", "Gebze, Kocaeli"],
      visitPurposes: [
        "New equipment proposal",
        "Maintenance agreement",
        "Pricing discussion",
      ],
      tasks: [
        "Send the revised proposal",
        "Confirm the technical demo date",
        "Review the maintenance agreement",
      ],
      contactNames: ["Alex Morgan", "Jordan Lee"],
      contactTitles: ["Procurement Manager", "Technical Manager"],
      representative: "Casey Taylor",
      teamMembers: ["Casey Taylor", "Alex Morgan", "Jordan Lee"],
      teamEmails: [
        "casey@vizyon.example",
        "alex@vizyon.example",
        "jordan@vizyon.example",
      ],
      activitySummary:
        "The new equipment proposal and technical demo date were approved.",
      product: "Industrial Control Unit",
      opportunity: "New equipment fleet",
      workspace: "Vizyon Sales Ltd.",
      customerSummary:
        "The last visit covered the maintenance package, warranty options, and the revised proposal date. The procurement manager is waiting for a technical demo date.",
      customerPromise: "Revised proposal",
      demoVisitPurpose: "Technical demo",
    };
  }
  return {
    companies: ["Atlas Medikal", "Nova Otomasyon", "Marmara Ambalaj"],
    areas: ["Şişli, İstanbul", "Ümraniye, İstanbul", "Gebze, Kocaeli"],
    visitPurposes: [
      "Yeni cihaz teklifi",
      "Bakım sözleşmesi",
      "Fiyat görüşmesi",
    ],
    tasks: [
      "Revize teklifi gönder",
      "Teknik demo tarihini netleştir",
      "Bakım sözleşmesini kontrol et",
    ],
    contactNames: ["Murat Aydın", "Deniz Şen"],
    contactTitles: ["Satın Alma Müdürü", "Teknik Müdür"],
    representative: "Ece Yılmaz",
    teamMembers: ["Burak Köse", "Ece Yılmaz", "Can Demir"],
    teamEmails: [
      "burak@vizyon.example",
      "ece@vizyon.example",
      "can@vizyon.example",
    ],
    activitySummary: "Yeni cihaz teklifi ve teknik demo tarihi onaylandı.",
    product: "Endüstriyel Kontrol Ünitesi",
    opportunity: "Yeni cihaz parkı",
    workspace: "Vizyon Satış A.Ş.",
    customerSummary:
      "Son görüşmede bakım paketi, garanti seçenekleri ve revize teklif tarihi konuşuldu. Satın alma müdürü teknik demo tarihini bekliyor.",
    customerPromise: "Revize teklif",
    demoVisitPurpose: "Teknik demo",
  };
}
