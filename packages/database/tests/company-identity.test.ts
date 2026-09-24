import { readFile } from "node:fs/promises";
import { PGlite } from "@electric-sql/pglite";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

const db = new PGlite();
const owner = "00000000-0000-4000-8000-000000000001";
const stranger = "00000000-0000-4000-8000-000000000002";
const ownWorkspace = "00000000-0000-4000-8000-000000000003";
const otherWorkspace = "00000000-0000-4000-8000-000000000004";
const organization = "00000000-0000-4000-8000-000000000005";
const organizationWorkspace = "00000000-0000-4000-8000-000000000006";
const sql = await readFile(
  new URL(
    "../migrations/0028_workspace_company_identity.up.sql",
    import.meta.url,
  ),
  "utf8",
);
const down = await readFile(
  new URL(
    "../migrations/0028_workspace_company_identity.down.sql",
    import.meta.url,
  ),
  "utf8",
);

beforeAll(async () => {
  await db.exec(`
    create schema auth;
    create role anon; create role authenticated; create role service_role;
    create function auth.uid() returns uuid language sql as $$ select nullif(current_setting('request.uid',true),'')::uuid $$;
    create function auth.role() returns text language sql as $$ select current_setting('request.role',true) $$;
    create type public.workspace_kind as enum ('personal','organization');
    create type public.membership_role as enum ('owner','field_sales');
    create table public.organizations(id uuid primary key, name text, owner_id uuid, slug text, created_at timestamptz default now(), archived_at timestamptz);
    create table public.workspaces(id uuid primary key, kind public.workspace_kind, name text, owner_user_id uuid, organization_id uuid, created_at timestamptz default now());
    create table public.memberships(organization_id uuid, user_id uuid, role public.membership_role);
    alter table public.organizations enable row level security;
    alter table public.workspaces enable row level security;
    create function public.has_organization_role(target uuid, roles public.membership_role[]) returns boolean
      language sql security definer as $$ select exists(select 1 from public.memberships
        where organization_id=target and user_id=auth.uid() and role=any(roles)) $$;
    create function public.workspace_entitlement(target uuid) returns jsonb language sql as $$
      select jsonb_build_object('readOnly',current_setting('request.read_only',true)='true') $$;
    create policy workspace_read on public.workspaces for select to authenticated
      using (owner_user_id = auth.uid() or public.has_organization_role(organization_id,array['owner']::public.membership_role[]));
    create policy organization_read on public.organizations for select to authenticated
      using (public.has_organization_role(id,array['owner']::public.membership_role[]));
    grant usage on schema public to authenticated;
    grant select,update on public.workspaces, public.organizations to authenticated;
    insert into public.workspaces(id,kind,name,owner_user_id,organization_id) values
      ('${ownWorkspace}','personal','Kişisel Alanım','${owner}',null),
      ('${otherWorkspace}','personal','Başka Şirket','${stranger}',null);
    insert into public.organizations(id,name,owner_id,slug) values ('${organization}','Eski Firma','${owner}','eski-firma');
    insert into public.workspaces(id,kind,name,owner_user_id,organization_id)
      values ('${organizationWorkspace}','organization','Eski Firma',null,'${organization}');
    insert into public.memberships values ('${organization}','${owner}','owner');
  `);
  await db.exec(sql);
  await db.exec(
    `select set_config('request.role','authenticated',false); select set_config('request.uid','${owner}',false); set role authenticated;`,
  );
}, 30000);

afterAll(async () => db.close());

describe("firma kimliği PostgreSQL davranışı", () => {
  it("kendi workspace adını değiştirir", async () => {
    await db.exec(
      `select public.rename_workspace_company('${ownWorkspace}','Ohrili Makina')`,
    );
    const result = await db.query<{ name: string }>(
      `select name from public.workspaces where id='${ownWorkspace}'`,
    );
    expect(result.rows[0].name).toBe("Ohrili Makina");
  });

  it("başkasının workspace adını değiştirmez", async () => {
    await expect(
      db.exec(
        `select public.rename_workspace_company('${otherWorkspace}','Sızma')`,
      ),
    ).rejects.toThrow();
  });

  it("organizasyon sahibinin canonical ve workspace adını birlikte değiştirir", async () => {
    await db.exec(
      `select public.rename_workspace_company('${organizationWorkspace}','Noesis Social')`,
    );
    const names = await db.query<{ workspace: string; organization: string }>(`
      select w.name as workspace,o.name as organization from public.workspaces w
      join public.organizations o on o.id=w.organization_id where w.id='${organizationWorkspace}'`);
    expect(names.rows[0]).toMatchObject({
      workspace: "Noesis Social",
      organization: "Noesis Social",
    });
  });

  it("read-only durumda değiştirmez", async () => {
    await db.exec(`select set_config('request.read_only','true',false)`);
    await expect(
      db.exec(
        `select public.rename_workspace_company('${ownWorkspace}','Yeni Ad')`,
      ),
    ).rejects.toThrow("Abonelik gerekli");
    await db.exec(`select set_config('request.read_only','false',false)`);
  });

  it("rollback fonksiyon ve politikaları kaldırır", async () => {
    await db.exec("reset role");
    await db.exec(down);
    const result = await db.query<{ count: string }>(
      "select count(*)::text as count from pg_proc where proname='rename_workspace_company'",
    );
    expect(result.rows[0].count).toBe("0");
  });
});
