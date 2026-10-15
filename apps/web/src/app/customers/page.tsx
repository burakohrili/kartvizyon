import { createSupabaseServerClient } from "@/lib/supabase/server";
import Link from "next/link";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";
import { formatDate, intlLocale } from "@/lib/i18n/locale";
import { getDemoRecords } from "@/lib/i18n/demo-records";

type Company = {
  id: string;
  name: string;
  display_name: string | null;
  phone: string | null;
  email: string | null;
  address: string | null;
  updated_at: string;
};

function demoCompaniesFor(locale: "en" | "tr"): Company[] {
  const demo = getDemoRecords(locale);
  return demo.companies.map((name, index) => ({
    id: `demo-${index + 1}`,
    name,
    display_name: null,
    phone: ["+90 212 555 12 20", "+90 216 555 33 10", "+90 262 555 08 05"][
      index
    ],
    email: [
      "procurement@atlasmedical.example",
      "info@novaautomation.example",
      "sales@marmarapackaging.example",
    ][index],
    address: demo.areas[index],
    updated_at: [
      "2026-08-02T10:42:00Z",
      "2026-08-01T15:10:00Z",
      "2026-07-30T12:00:00Z",
    ][index],
  }));
}

async function getCompanies(
  query: string,
  page: number,
  locale: "en" | "tr",
): Promise<{
  companies: Company[];
  demo: boolean;
  total: number;
  hasMore: boolean;
}> {
  const pageSize = 50;
  const offset = (page - 1) * pageSize;
  const demoCompanies = demoCompaniesFor(locale);
  const supabase = await createSupabaseServerClient();
  if (!supabase) {
    const normalized = query.toLocaleLowerCase(
      locale === "en" ? "en-US" : "tr-TR",
    );
    const companies = normalized
      ? demoCompanies.filter((company) =>
          [company.name, company.phone, company.email, company.address].some(
            (value) =>
              value
                ?.toLocaleLowerCase(locale === "en" ? "en-US" : "tr-TR")
                .includes(normalized),
          ),
        )
      : demoCompanies;
    return {
      companies,
      demo: true,
      total: companies.length,
      hasMore: false,
    };
  }
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return {
      companies: demoCompanies,
      demo: true,
      total: demoCompanies.length,
      hasMore: false,
    };
  const { data: workspaces } = await supabase
    .from("workspaces")
    .select("id")
    .limit(1);
  const workspaceId = workspaces?.[0]?.id;
  if (!workspaceId)
    return { companies: [], demo: false, total: 0, hasMore: false };
  let builder = supabase
    .from("companies")
    .select("id,name,display_name,phone,email,address,updated_at", {
      count: "exact",
    })
    .eq("workspace_id", workspaceId)
    .is("archived_at", null);
  if (query) {
    const escaped = query.replace(/[%_]/g, (char) => `\\${char}`);
    builder = builder.or(
      `name.ilike.%${escaped}%,display_name.ilike.%${escaped}%,phone.ilike.%${escaped}%,email.ilike.%${escaped}%,address.ilike.%${escaped}%`,
    );
  }
  const { data, count } = await builder
    .order("updated_at", { ascending: false })
    .range(offset, offset + pageSize - 1);
  const companies = (data as Company[] | null) ?? [];
  const total = count ?? offset + companies.length;
  return {
    companies,
    demo: false,
    total,
    hasMore: offset + companies.length < total,
  };
}

export default async function CustomersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; page?: string }>;
}) {
  const params = await searchParams;
  const locale = await getRequestLocale();
  const m = getMessages(locale).customers;
  const query = params.q?.trim() ?? "";
  const parsedPage = Number.parseInt(params.page ?? "1", 10);
  const page = Number.isFinite(parsedPage) ? Math.max(parsedPage, 1) : 1;
  const { companies, demo, total, hasMore } = await getCompanies(
    query,
    page,
    locale,
  );
  const pageHref = (target: number) => {
    const next = new URLSearchParams();
    if (query) next.set("q", query);
    if (target > 1) next.set("page", String(target));
    const suffix = next.toString();
    return suffix ? `/customers?${suffix}` : "/customers";
  };
  return (
    <main className="customers-page">
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.eyebrow}</span>
          <h1>{m.title}</h1>
          <p>{m.description}</p>
        </div>
        <div className="header-actions">
          <Link className="secondary-action" href="/import">
            {m.import}
          </Link>
          <Link className="primary button-link" href="/customers/new">
            {m.add}
          </Link>
        </div>
      </header>
      {demo && (
        <div className="demo-notice">
          <strong>{m.demoTitle}</strong> {m.demoBody}
        </div>
      )}
      <form className="customer-toolbar" action="/customers">
        <label className="search-field">
          <span>⌕</span>
          <input
            aria-label={m.searchLabel}
            name="q"
            defaultValue={query}
            placeholder={m.searchPlaceholder}
          />
        </label>
        <button type="submit">{m.search}</button>
        <span>
          {total} {total === 1 ? m.oneCompany : m.manyCompanies}
        </span>
      </form>
      <section className="customer-table-wrap">
        <table className="customer-table">
          <thead>
            <tr>
              <th>{m.company}</th>
              <th>{m.contact}</th>
              <th>{m.location}</th>
              <th>{m.lastUpdated}</th>
              <th>
                <span className="sr-only">{m.action}</span>
              </th>
            </tr>
          </thead>
          <tbody>
            {companies.map((company) => (
              <tr key={company.id}>
                <td>
                  <div className="company-cell">
                    <span>
                      {(company.display_name ?? company.name)
                        .slice(0, 2)
                        .toLocaleUpperCase(intlLocale(locale))}
                    </span>
                    <div>
                      <strong>{company.display_name ?? company.name}</strong>
                      <small>
                        {company.display_name ? company.name : m.memoryReady}
                      </small>
                    </div>
                  </div>
                </td>
                <td>
                  <strong>{company.phone ?? "—"}</strong>
                  <small>{company.email ?? m.noEmail}</small>
                </td>
                <td>{company.address ?? m.noLocation}</td>
                <td>
                  {formatDate(company.updated_at, locale, {
                    day: "numeric",
                    month: "short",
                    year: "numeric",
                  })}
                </td>
                <td>
                  <a
                    href={`/customers/${company.id}`}
                    aria-label={m.openDetails.replace(
                      "{company}",
                      company.name,
                    )}
                  >
                    →
                  </a>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {companies.length === 0 && (
          <div className="empty-state">
            <strong>{m.emptyTitle}</strong>
            <p>{m.emptyBody}</p>
            <Link className="primary button-link" href="/customers/new">
              {m.addFirst}
            </Link>
          </div>
        )}
        {(page > 1 || hasMore) && (
          <nav className="customer-toolbar" aria-label={m.pages}>
            {page > 1 ? (
              <Link className="secondary-action" href={pageHref(page - 1)}>
                {m.previous}
              </Link>
            ) : (
              <span />
            )}
            <span>
              {m.page} {page}
            </span>
            {hasMore && (
              <Link className="secondary-action" href={pageHref(page + 1)}>
                {m.next}
              </Link>
            )}
          </nav>
        )}
      </section>
    </main>
  );
}
