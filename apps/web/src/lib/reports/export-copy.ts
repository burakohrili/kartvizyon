import type { AppLocale } from "@/lib/i18n/locale";

export function reportExportCopy(locale: AppLocale) {
  return locale === "en"
    ? {
        sheetName: "Approved visits",
        date: "Date",
        company: "Company",
        representative: "Representative",
        outcome: "Outcome",
        summary: "Approved summary",
        followUps: "Follow-ups",
        notSpecified: "Not specified",
        title: "Approved field visit report",
        visits: "visits",
        positive: "positive outcomes",
        followUpsCount: "follow-ups",
        summaryMissing: "No summary available",
      }
    : {
        sheetName: "Onaylı ziyaretler",
        date: "Tarih",
        company: "Firma",
        representative: "Temsilci",
        outcome: "Sonuç",
        summary: "Onaylı özet",
        followUps: "Takip sayısı",
        notSpecified: "belirtilmedi",
        title: "Onaylı saha ziyaretleri raporu",
        visits: "ziyaret",
        positive: "olumlu sonuç",
        followUpsCount: "takip",
        summaryMissing: "Özet bulunmuyor",
      };
}
