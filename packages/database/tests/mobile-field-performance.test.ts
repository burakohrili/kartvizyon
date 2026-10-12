import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const migration = await readFile(
  resolve(
    import.meta.dirname,
    "../migrations/0036_mobile_field_performance.up.sql",
  ),
  "utf8",
);

describe("mobil saha performans migration'ı", () => {
  it("hız sınırı upsert'inde belirsiz sütun listesini kullanmaz", () => {
    expect(migration).toContain(
      "on conflict on constraint api_rate_limits_pkey",
    );
    expect(migration).not.toMatch(/on conflict\s*\(user_id,\s*route_key\)/i);
  });

  it("görev listesinin workspace/tarih sıralamasını indeksler", () => {
    expect(migration).toContain("tasks_workspace_due_id_idx");
    expect(migration).toContain(
      "(workspace_id, due_at asc nulls last, id asc)",
    );
  });
});
