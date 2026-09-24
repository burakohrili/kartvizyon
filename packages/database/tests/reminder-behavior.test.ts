import { readFile } from "node:fs/promises";
import { PGlite } from "@electric-sql/pglite";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

const db = new PGlite();
const user = "00000000-0000-4000-8000-000000000001";
const other = "00000000-0000-4000-8000-000000000002";
const workspace = "00000000-0000-4000-8000-000000000010";
const company = "00000000-0000-4000-8000-000000000020";
const visit = "00000000-0000-4000-8000-000000000030";
const todayVisit = "00000000-0000-4000-8000-000000000031";
const task = "00000000-0000-4000-8000-000000000040";
const migration = await readFile(
  new URL("../migrations/0029_reminders_notifications.up.sql", import.meta.url),
  "utf8",
);

beforeAll(async () => {
  await db.exec(`
    create schema auth;
    create role anon; create role authenticated; create role service_role;
    create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.uid',true),'')::uuid $$;
    create function auth.role() returns text language sql as $$ select current_setting('request.role',true) $$;
    create table public.profiles(id uuid primary key, timezone text not null default 'UTC');
    create table public.workspaces(id uuid primary key);
    create function public.can_access_workspace(uuid) returns boolean language sql as $$ select true $$;
    create table public.companies(id uuid primary key, name text not null);
    create table public.visits(
      id uuid primary key, company_id uuid, workspace_id uuid, organization_id uuid,
      representative_id uuid, status text, planned_start_at timestamptz,
      planned_end_at timestamptz, completed_at timestamptz
    );
    create table public.tasks(
      id uuid primary key, workspace_id uuid, organization_id uuid, title text,
      status text, due_at timestamptz, assigned_to uuid
    );
    create table public.notifications(
      id uuid primary key default gen_random_uuid(), workspace_id uuid,
      organization_id uuid, user_id uuid, type text, title text, body text,
      resource_type text, resource_id text, action_url text, read_at timestamptz,
      created_at timestamptz default now()
    );
    alter table public.notifications enable row level security;
    create policy notifications_owner_all on public.notifications for all using (user_id=auth.uid()) with check(user_id=auth.uid());
    grant all on public.notifications to authenticated;
  `);
  await db.exec(migration);
  await db.exec(`
    select set_config('request.role','service_role',false);
    insert into public.profiles values ('${user}','Europe/Istanbul'),('${other}','UTC');
    insert into public.workspaces values ('${workspace}');
    insert into public.companies values ('${company}','ABC Makina');
    insert into public.visits values (
      '${visit}','${company}','${workspace}',null,'${user}','draft',
      '2026-09-22 06:30:00Z','2026-09-22 07:30:00Z',null
    ),(
      '${todayVisit}','${company}','${workspace}',null,'${user}','draft',
      '2026-09-21 10:00:00Z','2026-09-21 11:00:00Z',null
    );
    insert into public.tasks values (
      '${task}','${workspace}',null,'Teklif dosyasını gönder','open',
      '2026-09-21 06:00:00Z','${user}'
    );
  `);
}, 30000);

afterAll(async () => db.close());

async function process(at: string) {
  return db.query<{ result: { created: number } }>(
    "select public.process_reminders($1, 500) result",
    [at],
  );
}

describe("reminder PostgreSQL behavior", () => {
  it("creates the local-morning field plan and due-today task once", async () => {
    const first = await process("2026-09-21 05:30:00Z");
    expect(first.rows[0].result.created).toBe(3);
    const retry = await process("2026-09-21 05:30:00Z");
    expect(retry.rows[0].result.created).toBe(0);
  });

  it("creates 24-hour and missed reminders once with a 30-minute tolerance", async () => {
    await db.exec(
      `update public.visits set completed_at='2026-09-21 11:00:00Z' where id='${todayVisit}'`,
    );
    // The visit's 24-hour reminder and the task's first overdue event are
    // independent domain occurrences.
    expect((await process("2026-09-21 06:30:00Z")).rows[0].result.created).toBe(
      2,
    );
    expect((await process("2026-09-22 07:45:00Z")).rows[0].result.created).toBe(
      0,
    );
    expect(
      (await process("2026-09-22 08:00:00Z")).rows[0].result.created,
    ).toBeGreaterThanOrEqual(1);
    const rows = await db.query<{ type: string; user_id: string }>(
      "select type,user_id from public.notifications",
    );
    expect(rows.rows.every((row) => row.user_id === user)).toBe(true);
    expect(rows.rows.map((row) => row.type)).toContain("visit_missed");
  });

  it("does not let authenticated clients insert arbitrary notifications", async () => {
    const privilege = await db.query<{ allowed: boolean }>(
      "select has_table_privilege('authenticated','public.notifications','insert') allowed",
    );
    expect(privilege.rows[0].allowed).toBe(false);
  });
});
