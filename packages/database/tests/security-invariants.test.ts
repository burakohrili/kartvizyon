import { readdir, readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Migration'lar üzerinde çalışan yapısal güvenlik denetimleri.
 *
 * Bu testler tek tek migration'ların içeriğini değil, **tüm şemanın toplamında
 * ihlal edilmemesi gereken değişmezleri** kontrol eder. Yeni bir migration
 * eklendiğinde kendiliğinden kapsar.
 */

const directory = resolve(import.meta.dirname, "../migrations");
const files = (await readdir(directory)).sort();
const upFiles = files.filter((file) => file.endsWith(".up.sql"));
const downFiles = files.filter((file) => file.endsWith(".down.sql"));

const upSql = await Promise.all(
  upFiles.map(async (file) => ({
    file,
    sql: await readFile(resolve(directory, file), "utf8"),
  })),
);
const allUpSql = upSql.map((entry) => entry.sql).join("\n");

/** `create table public.<ad> (` biçimindeki tüm tablo adları. */
function createdTables(sql: string): string[] {
  return [
    ...sql.matchAll(/create table (?:if not exists )?public\.([a-z0-9_]+)/gi),
  ].map((match) => match[1]);
}

describe("satır bazlı güvenlik kapsamı", () => {
  const tables = createdTables(allUpSql);

  it("public şemasında en az bir tablo bulur", () => {
    expect(tables.length).toBeGreaterThan(10);
  });

  it.each(tables)("%s tablosunda RLS etkinleştirilir", (table) => {
    // Tek bir tabloda RLS unutulursa o tablodaki tüm kiracı verisi anon
    // anahtarla okunabilir hale gelir. Bu, üründeki en pahalı tek hatadır.
    const pattern = new RegExp(
      `alter table public[.]${table} enable row level security`,
      "i",
    );
    expect(allUpSql).toMatch(pattern);
  });

  // RLS açık + policy yok = herkese kapalı. Bu, yalnız `security definer`
  // fonksiyonlarla yazılan tablolar için doğru ve en kısıtlayıcı durumdur.
  // Listeye ekleme yapmak bilinçli bir karar olmalıdır.
  const DENY_ALL_BY_DESIGN = new Set([
    // Yalnız consume_api_rate_limit tarafından yazılır; istemci hiç okumaz.
    "api_rate_limits",
  ]);

  it.each(tables.filter((table) => !DENY_ALL_BY_DESIGN.has(table)))(
    "%s tablosu için en az bir policy tanımlar",
    (table) => {
      const pattern = new RegExp(
        `create policy [a-z0-9_]+ on public[.]${table}`,
        "i",
      );
      expect(allUpSql).toMatch(pattern);
    },
  );

  it.each([...DENY_ALL_BY_DESIGN])(
    "%s tablosu bilinçli olarak policy'siz kalır ve istemciye açılmaz",
    (table) => {
      const pattern = new RegExp(
        `create policy [a-z0-9_]+ on public[.]${table}`,
        "i",
      );
      expect(
        allUpSql,
        `${table} için policy eklendiyse bu istisna listesinden çıkarılmalıdır`,
      ).not.toMatch(pattern);
      expect(allUpSql).toMatch(
        new RegExp(
          `alter table public[.]${table} enable row level security`,
          "i",
        ),
      );
    },
  );
});

describe("security definer fonksiyonları", () => {
  const definerBlocks = [
    ...allUpSql.matchAll(
      /create (?:or replace )?function public\.([a-z0-9_]+)\s*\(([^)]*)\)[\s\S]*?security definer([\s\S]{0,120})/gi,
    ),
  ];

  it("en az bir security definer fonksiyon vardır", () => {
    expect(definerBlocks.length).toBeGreaterThan(0);
  });

  it.each(definerBlocks.map((match) => [match[1], match[3]] as const))(
    "%s fonksiyonu search_path'i sabitler",
    (_name, tail) => {
      // search_path sabitlenmezse arayan kullanıcı kendi şemasını öne alıp
      // fonksiyonun çağırdığı tabloyu değiştirebilir.
      expect(tail).toMatch(/set search_path = ''/);
    },
  );
});

describe("storage kovaları", () => {
  const bucketInserts = [
    ...allUpSql.matchAll(/insert into storage\.buckets[\s\S]{0,400}?;/gi),
  ].map((match) => match[0]);

  it("en az bir kova tanımlar", () => {
    expect(bucketInserts.length).toBeGreaterThan(0);
  });

  it.each(bucketInserts.map((sql, index) => [index, sql] as const))(
    "%i numaralı kova public olarak açılmaz",
    (_index, sql) => {
      // Ses, belge ve dışa aktarma kovaları imzalı URL ile sunulur.
      expect(sql).not.toMatch(/,\s*true\s*,/);
    },
  );
});

describe("rollback bütünlüğü", () => {
  it("her up dosyasının down karşılığı vardır", () => {
    for (const file of upFiles) {
      expect(downFiles).toContain(file.replace(".up.sql", ".down.sql"));
    }
  });

  it("migration numaraları benzersiz ve sıralıdır", () => {
    const numbers = upFiles.map((file) => Number(file.slice(0, 4)));
    expect(new Set(numbers).size).toBe(numbers.length);
    expect([...numbers].sort((a, b) => a - b)).toEqual(numbers);
  });
});

describe("sır sızıntısı", () => {
  it("migration dosyalarında gömülü anahtar bulunmaz", () => {
    const secretLike =
      /(eyJ[A-Za-z0-9_-]{30,}|sk-[A-Za-z0-9]{20,}|service_role_key\s*=\s*'[^']+')/;
    for (const { file, sql } of upSql) {
      expect(sql, `${file} içinde sır benzeri dize`).not.toMatch(secretLike);
    }
  });
});
