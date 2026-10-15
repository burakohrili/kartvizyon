import { readFile } from "node:fs/promises";
import { PGlite } from "@electric-sql/pglite";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

const db = new PGlite();
const migration = await readFile(
  new URL(
    "../migrations/0037_visit_planning_schema_repair.up.sql",
    import.meta.url,
  ),
  "utf8",
);

beforeAll(async () => {
  // Simulate a production database where migration 0030 was skipped.
  await db.exec(`
    create table public.visits(
      id uuid primary key,
      planned_start_at timestamptz,
      planned_end_at timestamptz,
      check_in_type text
    )
  `);
  await db.exec(migration);
});

afterAll(async () => db.close());

describe("visit planning schema repair", () => {
  it("restores planning fields and validation on a lagging schema", async () => {
    await db.exec(`
      insert into public.visits(id, visit_type, planning_note)
      values (
        '00000000-0000-4000-8000-000000000037',
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

    await expect(
      db.exec(`
        insert into public.visits(id, visit_type)
        values ('00000000-0000-4000-8000-000000000038', 'unknown')
      `),
    ).rejects.toThrow();
  });

  it("is safe to rerun", async () => {
    await db.exec(migration);
    const result = await db.query<{ count: string }>(`
      select count(*)::text as count
      from pg_constraint
      where conrelid = 'public.visits'::regclass
        and conname in ('visits_visit_type_check', 'visits_planning_note_check')
    `);
    expect(result.rows[0].count).toBe("2");
  });
});
