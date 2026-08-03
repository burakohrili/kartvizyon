import { describe, expect, it } from "vitest";
import { parseCsv, sanitizeCell, suggestMapping, toRecords } from "./parse";

describe("CSV parser", () => {
  it("tırnak içindeki virgülü korur", () =>
    expect(parseCsv('Firma,Adres\nAtlas,"Şişli, İstanbul"')[1]).toEqual([
      "Atlas",
      "Şişli, İstanbul",
    ]));
  it("CSV formül enjeksiyonunu etkisizleştirir", () =>
    expect(sanitizeCell("=HYPERLINK('x')")).toBe("'=HYPERLINK('x')"));
  it("artı işaretli telefonu korur", () =>
    expect(sanitizeCell("+90 212 555 00 01")).toBe("+90 212 555 00 01"));
  it("tekrar eden kolonlara benzersiz ad verir", () =>
    expect(
      toRecords([
        ["Telefon", "Telefon"],
        ["1", "2"],
      ]).headers,
    ).toEqual(["Telefon", "Telefon (2)"]));
  it("Türkçe kolonları önerir", () =>
    expect(suggestMapping(["Firma Adı", "Telefon", "E-posta"]).name).toBe(
      "Firma Adı",
    ));
});
