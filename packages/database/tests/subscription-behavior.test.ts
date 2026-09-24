import { readFile } from "node:fs/promises";
import { PGlite } from "@electric-sql/pglite";
import { beforeAll, afterAll, describe, it, expect } from "vitest";
const db = new PGlite();
const user = "00000000-0000-4000-8000-000000000001";
const workspace = "00000000-0000-4000-8000-000000000002";
const outsider = "00000000-0000-4000-8000-000000000003";
const sql = await readFile(
  new URL("../migrations/0027_trial_subscription.up.sql", import.meta.url),
  "utf8",
);
const down = await readFile(
  new URL("../migrations/0027_trial_subscription.down.sql", import.meta.url),
  "utf8",
);
// Supabase auth/storage contracts; execute the actual migration in PostgreSQL.
beforeAll(async () => {
  await db.exec(`
    create schema auth; create schema storage;
    create role anon; create role authenticated; create role service_role;
    create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.uid',true),'')::uuid $$;
    create function auth.role() returns text language sql as $$ select current_setting('request.role',true) $$;
    create table auth.users(id uuid primary key,email_confirmed_at timestamptz,last_sign_in_at timestamptz);
    create table public.organizations(id uuid primary key,owner_id uuid);
    create table public.workspaces(id uuid primary key,owner_user_id uuid,organization_id uuid,created_at timestamptz default now());
    create table public.subscription_plans(id text primary key,name text,monthly_price_try numeric,price_per_seat_try numeric,annual_price_try numeric,monthly_ai_minutes integer,max_ocr integer,max_companies integer,monthly_document_bytes bigint,seat_limit integer,features jsonb);
    insert into public.subscription_plans values ('individual','Bireysel',349,349,3490,120,60,null,5368709120,1,'[]'),('free','Ücretsiz',0,0,0,10,5,5,100,1,'[]');
    create table public.workspace_subscriptions(workspace_id uuid primary key,plan_id text,status text,provider text,current_period_start timestamptz,current_period_end timestamptz,trial_ends_at timestamptz,seat_quantity integer default 1);
    create table public.ai_topup_packages(active boolean);
    create table storage.objects(bucket_id text);
    create function public.can_access_workspace(w uuid) returns boolean language sql as $$ select exists(select 1 from public.workspaces where id=w and owner_user_id=auth.uid()) $$;
  `);
  const tableLoop = sql.match(/foreach tab in array array\[([\s\S]*?)\] loop/);
  if (!tableLoop) throw new Error("Subscription guard table loop not found");
  const tableNames = tableLoop[1].match(/'([^']+)'/g);
  if (!tableNames) throw new Error("Subscription guard tables not found");
  const tables = tableNames.map((x) => x.slice(1, -1));
  for (const table of tables)
    await db.exec(
      `create table public.${table}(id uuid default gen_random_uuid(),workspace_id uuid);`,
    );
  await db.exec(sql);
  await db.exec(`select set_config('request.role','authenticated',false); select set_config('request.uid','${user}',false);
    insert into auth.users values ('${user}',now(),now()),('${outsider}',now(),now());
    insert into public.workspaces(id,owner_user_id) values ('${workspace}','${user}');`);
}, 30000);
afterAll(async () => {
  await db.close();
});
async function entitlement() {
  return (
    await db.query<{ e: Record<string, unknown> }>(
      `select public.workspace_entitlement('${workspace}') e`,
    )
  ).rows[0].e;
}
async function reserve(key: string, ocr = 0, audio = 0, summaries = 0) {
  return (
    await db.query<{ r: Record<string, unknown> }>(
      `select public.reserve_ai_quota($1,$2,$3,$4,$5,$6) r`,
      [workspace, user, key, ocr, audio, summaries],
    )
  ).rows[0].r;
}
describe("trial and subscription PostgreSQL behavior", () => {
  it("gives one verified-account trial with the approved quotas", async () => {
    const e = await entitlement();
    expect(e.trialActive).toBe(true);
    expect(e.limits).toMatchObject({
      ocr: 60,
      aiMinutes: 120,
      aiSummaries: 60,
    });
    await db.exec(
      `update auth.users set last_sign_in_at=now() where id='${user}';`,
    );
    expect(
      (
        await db.query(
          `select * from public.account_trials where user_id='${user}'`,
        )
      ).rows,
    ).toHaveLength(1);
  });
  it("rejects foreign-workspace access", async () => {
    await db.exec(`select set_config('request.uid','${outsider}',false)`);
    await expect(entitlement()).rejects.toThrow("Workspace access denied");
    await db.exec(`select set_config('request.uid','${user}',false)`);
  });
  it("reserves the complete audio and summary budget and rejects overflow", async () => {
    const first = await reserve("first", 60, 7200, 60);
    expect(first.id).toBeTruthy();
    expect((await reserve("second", 1)).code).toBe("quota_exceeded");
    expect((await reserve("second", 0, 1)).code).toBe("quota_exceeded");
    expect((await reserve("second", 0, 0, 1)).code).toBe("quota_exceeded");
    expect((await reserve("first", 60, 7200, 60)).code).toBe(
      "operation_pending",
    );
    await db.exec(
      `update public.ai_quota_operations set status='completed',response='{"ok":true}'`,
    );
    expect((await reserve("first", 60, 7200, 60)).response).toEqual({
      ok: true,
    });
  });
  it("does not double spend on concurrent requests", async () => {
    await db.exec(`update public.ai_quota_operations set status='failed'`);
    const results = await Promise.all([
      reserve("parallel1", 31),
      reserve("parallel2", 31),
    ]);
    expect(results.filter((r) => r.id)).toHaveLength(1);
    expect(results.filter((r) => r.code === "quota_exceeded")).toHaveLength(1);
  });
  it("expires trial at its boundary and blocks direct writes but allows reads", async () => {
    await db.exec(
      `update public.account_trials set started_at=now()-interval '14 days',ends_at=now() where user_id='${user}'`,
    );
    expect((await entitlement()).readOnly).toBe(true);
    await expect(
      db.exec(
        `insert into public.companies(workspace_id) values ('${workspace}')`,
      ),
    ).rejects.toThrow("Abonelik gerekli");
    await expect(
      db.query("select * from public.companies"),
    ).resolves.toBeTruthy();
    expect((await reserve("expired", 1)).code).toBe("subscription_required");
  });
  it("starts full paid allowance independently from trial use; checks expiry even if active", async () => {
    await db.exec(
      `insert into public.workspace_subscriptions(workspace_id,plan_id,status,provider,current_period_start,current_period_end) values ('${workspace}','individual','active','apple',now(),now()+interval '1 year')`,
    );
    expect((await entitlement()).limits).toMatchObject({
      ocr: 125,
      aiMinutes: 240,
      aiSummaries: 125,
    });
    expect((await reserve("paid", 125, 14400, 125)).id).toBeTruthy();
    await db.exec(
      `update public.workspace_subscriptions set current_period_end=now()-interval '1 second'`,
    );
    expect((await entitlement()).readOnly).toBe(true);
  });
  it("uses clamped monthly anniversaries for annual billing", async () => {
    const r = await db.query<{ v: Date }>(
      `select public.usage_month_start('2026-01-31 12:00Z','2026-03-01 00:00Z') v`,
    );
    expect(new Date(r.rows[0].v).toISOString()).toBe(
      "2026-02-28T12:00:00.000Z",
    );
  });
  it("does not grant trial before verified login", async () => {
    await db.exec(
      `insert into auth.users(id) values ('00000000-0000-4000-8000-000000000004')`,
    );
    expect(
      (
        await db.query(
          `select * from public.account_trials where user_id='00000000-0000-4000-8000-000000000004'`,
        )
      ).rows,
    ).toHaveLength(0);
  });
  it("prevents authenticated users from reserving arbitrary quota directly", async () => {
    const r = await db.query<{ allowed: boolean }>(
      `select has_function_privilege('authenticated','public.reserve_ai_quota(uuid,uuid,text,integer,integer,integer)','execute') allowed`,
    );
    expect(r.rows[0].allowed).toBe(false);
  });
  it("rollback removes guards without destroying trial history", async () => {
    await db.exec(down);
    expect(
      (await db.query("select * from public.account_trials")).rows.length,
    ).toBeGreaterThan(0);
    expect(
      (await db.query("select * from public.ai_quota_operations")).rows.length,
    ).toBeGreaterThan(0);
  });
});
