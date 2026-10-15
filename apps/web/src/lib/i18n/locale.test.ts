import { describe, expect, it } from "vitest";
import {
  formatCurrency,
  formatDate,
  formatDateTime,
  formatNumber,
  intlLocale,
  resolveLocale,
} from "./locale";

describe("locale preferences and formatting", () => {
  it("accepts English locale tags and safely defaults unknown values to Turkish", () => {
    expect(resolveLocale("en")).toBe("en");
    expect(resolveLocale("en-GB")).toBe("en");
    expect(resolveLocale("tr-TR")).toBe("tr");
    expect(resolveLocale("fr")).toBe("tr");
    expect(resolveLocale(null)).toBe("tr");
    expect(intlLocale("en")).toBe("en-US");
  });

  it("formats date, time, number, and currency without changing values", () => {
    const date = new Date("2026-08-20T09:05:00.000Z");
    expect(
      formatDate(date, "en", {
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      }),
    ).toBe("08/20/2026");
    expect(
      formatDate(date, "tr", {
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      }),
    ).toBe("20.08.2026");
    expect(
      formatDateTime(date, "en", {
        timeZone: "UTC",
        hour: "2-digit",
        minute: "2-digit",
        hourCycle: "h23",
      }),
    ).toContain("09:05");
    expect(formatNumber(1250.5, "en")).toBe("1,250.5");
    expect(formatNumber(1250.5, "tr")).toBe("1.250,5");
    expect(formatCurrency(449, "TRY", "en")).toContain("449.00");
    expect(formatCurrency(449, "TRY", "tr")).toContain("449,00");
  });
});
