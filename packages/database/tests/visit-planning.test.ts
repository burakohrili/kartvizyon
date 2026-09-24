import { readFile } from "node:fs/promises";
import { PGlite } from "@electric-sql/pglite";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

const db = new PGlite();
const migration = await readFile(
  new URL("../migrations/0030_visit_planning_metadata.up.sql", import.meta.url),
  "utf8",
);

beforeAll(async () => {
  await db.exec("create table public.visits(id uuid primary key)");
  await db.exec(migration);
});

afterAll(async () => db.close());

describe("visit planning metadata", () => {
  it("stores a supported visit type and a separate planning note", async () => {
    await db.exec(`
      insert into public.visits(id, visit_type, planning_note)
      values (
        '00000000-0000-4000-8000-000000000001',
        'quote_follow_up',
        'Satın alma müdürü de katılacak.'
      )
    `);
    const result = await db.query<{
      visit_type: string;
      planning_note: string;
    }>("select visit_type, planning_note from public.visits");
    expect(result.rows[0]).toEqual({
      visit_type: "quote_follow_up",
      planning_note: "Satın alma müdürü de katılacak.",
    });
  });

  it("rejects unknown visit types and overlong planning notes", async () => {
    await expect(
      db.exec(`
        insert into public.visits(id, visit_type)
        values ('00000000-0000-4000-8000-000000000002', 'unknown')
      `),
    ).rejects.toThrow();
    await expect(
      db.exec(`
        insert into public.visits(id, planning_note)
        values (
          '00000000-0000-4000-8000-000000000003',
          repeat('x', 2001)
        )
      `),
    ).rejects.toThrow();
  });
});
