import { describe, expect, it } from "vitest";
import { reportExportCopy } from "./export-copy";

describe("localized report export copy", () => {
  it("provides English export labels without translating stored report content", () => {
    expect(reportExportCopy("en")).toMatchObject({
      sheetName: "Approved visits",
      date: "Date",
      outcome: "Outcome",
      summary: "Approved summary",
      summaryMissing: "No summary available",
    });
  });

  it("preserves Turkish as the existing default", () => {
    expect(reportExportCopy("tr")).toMatchObject({
      sheetName: "Onaylı ziyaretler",
      date: "Tarih",
      outcome: "Sonuç",
      summary: "Onaylı özet",
    });
  });
});
