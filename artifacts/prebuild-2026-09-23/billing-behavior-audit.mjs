import { readFile, writeFile } from "node:fs/promises";
import { PGlite } from "@electric-sql/pglite";

// Isolated in-memory PostgreSQL. No environment variables or external services.
const db = new PGlite();
const root = new URL("../../", import.meta.url);
const sql26 = await readFile(
  new URL(
    "packages/database/migrations/0026_native_store_billing.up.sql",
    root,
  ),
  "utf8",
);
const sql27 = await readFile(
  new URL("packages/database/migrations/0027_trial_subscription.up.sql", root),
  "utf8",
);
const sql35 = await readFile(
  new URL(
    "packages/database/migrations/0035_store_billing_reconciliation.up.sql",
    root,
  ),
  "utf8",
);
const userA = "00000000-0000-4000-8000-000000000001";
const userB = "00000000-0000-4000-8000-000000000002";
const wsA = "00000000-0000-4000-8000-000000000011";
const wsB = "00000000-0000-4000-8000-000000000012";
await db.exec(`
create schema auth;
create role anon; create role authenticated; create role service_role;
create function auth.uid() returns uuid language sql as $$select '${userA}'::uuid$$;
create function auth.role() returns text language sql as $$select 'service_role'::text$$;
create type public.subscription_status as enum ('trialing','active','past_due','cancelled');
create table public.profiles(id uuid primary key);
create table public.organizations(id uuid primary key,owner_id uuid);
create table public.workspaces(id uuid primary key,kind text,owner_user_id uuid,organization_id uuid);
create table public.subscription_plans(id text primary key,name text,distribution text,
 max_companies integer,monthly_ai_minutes integer,max_ocr integer,monthly_ai_summaries integer,
 monthly_document_bytes bigint,seat_limit integer);
create table public.workspace_subscriptions(workspace_id uuid primary key,organization_id uuid,
 plan_id text,status public.subscription_status,seat_quantity integer,provider text,
 provider_customer_id text,provider_subscription_id text,provider_original_transaction_id text,
 current_period_start timestamptz,current_period_end timestamptz,cancel_at_period_end boolean,
 trial_ends_at timestamptz,updated_at timestamptz);
create table public.account_trials(user_id uuid primary key,started_at timestamptz,ends_at timestamptz);
create function public.can_access_workspace(w uuid) returns boolean language sql as $$select true$$;
insert into public.profiles values ('${userA}'),('${userB}');
insert into public.workspaces values ('${wsA}','personal','${userA}',null),('${wsB}','personal','${userB}',null);
insert into public.subscription_plans values ('individual','Bireysel','iap',null,240,125,125,5368709120,1),('free','Read only','free',0,0,0,0,0,1);
`);
await db.exec(sql26);
for (const name of ["usage_month_start", "workspace_entitlement"]) {
  const start = sql27.indexOf(`create function public.${name}(`);
  const end = sql27.indexOf("end $$;", start) + "end $$;".length;
  if (start < 0 || end < start) throw new Error("Migration function not found");
  await db.exec(sql27.slice(start, end));
}
await db.exec(sql35);
const now = Date.now();
async function apply(overrides = {}) {
  const e = {
    id: "initial",
    type: "INITIAL_PURCHASE",
    env: "PRODUCTION",
    user: userA,
    ws: wsA,
    tx: "tx1",
    original: "origin1",
    status: "active",
    purchased: now - 86400000,
    expires: now + 86400000 * 25,
    auto: true,
    occurred: now,
    ...overrides,
  };
  return (
    await db.query(
      `select public.apply_store_billing_event($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17) result`,
      [
        e.id,
        e.type,
        "a".repeat(64),
        e.env,
        "apple",
        e.user,
        e.ws,
        "individual",
        "app.kartvizyon.mobile.premium.monthly",
        null,
        e.tx,
        e.original,
        e.status,
        new Date(e.purchased).toISOString(),
        new Date(e.expires).toISOString(),
        e.auto,
        new Date(e.occurred).toISOString(),
      ],
    )
  ).rows[0].result;
}
async function entitlement(ws = wsA) {
  return (await db.query("select public.workspace_entitlement($1) e", [ws]))
    .rows[0].e;
}
async function transfer() {
  return (
    await db.query(
      `select public.transfer_store_billing_ownership($1,$2,$3,$4,$5,$6,$7,$8,$9) result`,
      [
        "transfer-event",
        "b".repeat(64),
        "PRODUCTION",
        "apple",
        userA,
        wsA,
        userB,
        wsB,
        new Date(now + 2000).toISOString(),
      ],
    )
  ).rows[0].result;
}
const results = [];
async function check(name, run) {
  await db.exec("begin");
  try {
    const result = await run();
    results.push({ name, ...result, status: result.ok ? "PASS" : "FAIL" });
  } catch (e) {
    results.push({ name, status: "ERROR", error: e.message });
  } finally {
    await db.exec("rollback");
  }
}
await check("initial purchase grants paid quota", async () => {
  await apply();
  const e = await entitlement();
  return { ok: !e.readOnly && e.limits.aiSummaries === 125, actual: e };
});
await check(
  "duplicate and older same-transaction events are ignored",
  async () => {
    await apply();
    const duplicate = await apply();
    const stale = await apply({
      id: "older",
      occurred: now - 1000,
      status: "cancelled",
    });
    return {
      ok: duplicate === "duplicate" && stale === "stale",
      actual: { duplicate, stale },
    };
  },
);
await check("cancellation preserves access until paid expiry", async () => {
  await apply({ type: "CANCELLATION", status: "cancelled", auto: false });
  const e = await entitlement();
  return { ok: !e.readOnly, actual: e.status };
});
await check("expired subscription becomes read-only", async () => {
  await apply({ type: "EXPIRATION", status: "cancelled", expires: now - 1000 });
  const e = await entitlement();
  return { ok: e.readOnly, actual: e.status };
});
await check("organization workspace rejects native store billing", async () => {
  await db.exec(
    `update public.workspaces set kind='organization' where id='${wsA}'`,
  );
  try {
    await apply();
    return { ok: false, actual: "accepted" };
  } catch (e) {
    return {
      ok: e.message.includes("owner personal workspace"),
      actual: e.message,
    };
  }
});
await check(
  "sandbox must not overwrite a production paid subscription",
  async () => {
    await apply();
    await apply({
      id: "sandbox",
      env: "SANDBOX",
      tx: "sandbox-tx",
      original: "sandbox-origin",
      occurred: now + 1000,
      expires: now + 300000,
    });
    const e = await entitlement();
    return {
      ok: new Date(e.accessEndsAt).getTime() === now + 86400000 * 25,
      actual: e.accessEndsAt,
      expected: new Date(now + 86400000 * 25).toISOString(),
    };
  },
);
await check(
  "transaction reassignment must not retain two paid workspaces",
  async () => {
    await apply();
    await apply({
      id: "new-owner",
      user: userB,
      ws: wsB,
      occurred: now + 1000,
    });
    const a = await entitlement(wsA),
      b = await entitlement(wsB);
    return {
      ok: a.readOnly || b.readOnly,
      actual: { oldOwnerReadOnly: a.readOnly, newOwnerReadOnly: b.readOnly },
    };
  },
);
await check("transfer event moves access atomically", async () => {
  await apply();
  const outcome = await transfer();
  const a = await entitlement(wsA),
    b = await entitlement(wsB);
  return {
    ok: outcome === "processed" && a.readOnly && !b.readOnly,
    actual: {
      outcome,
      oldOwnerReadOnly: a.readOnly,
      newOwnerReadOnly: b.readOnly,
    },
  };
});
await check(
  "older other-transaction expiry must not revoke newer purchase",
  async () => {
    await apply({
      id: "new-purchase",
      tx: "new-tx",
      original: "new-origin",
      occurred: now + 1000,
    });
    await apply({
      id: "old-expiry",
      type: "EXPIRATION",
      status: "cancelled",
      expires: now - 1000,
      occurred: now - 500,
    });
    const e = await entitlement();
    return { ok: !e.readOnly, actual: e.status };
  },
);
await check("scheduled pause must preserve unexpired paid access", async () => {
  await apply();
  await apply({
    id: "pause",
    type: "SUBSCRIPTION_PAUSED",
    status: "past_due",
    auto: false,
    occurred: now + 1000,
  });
  const e = await entitlement();
  return { ok: !e.readOnly, actual: e.status };
});
await check("billing issue must preserve remaining paid access", async () => {
  await apply();
  await apply({
    id: "billing-issue",
    type: "BILLING_ISSUE",
    status: "past_due",
    auto: false,
    occurred: now + 1000,
  });
  const e = await entitlement();
  return { ok: !e.readOnly, actual: e.status };
});
await db.close();
await writeFile(
  new URL("billing-behavior-results.json", import.meta.url),
  JSON.stringify(results, null, 2),
);
for (const r of results) console.log(`${r.status}: ${r.name}`);
console.log(
  JSON.stringify({
    pass: results.filter((r) => r.status === "PASS").length,
    fail: results.filter((r) => r.status === "FAIL").length,
    error: results.filter((r) => r.status === "ERROR").length,
  }),
);
process.exitCode = results.some((r) => r.status !== "PASS") ? 1 : 0;
