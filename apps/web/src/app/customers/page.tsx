import { createSupabaseServerClient } from "@/lib/supabase/server";
import Link from "next/link";
import { DemoBanner } from "@/app/demo-banner";

type Company = {
  id: string;
  name: string;
  display_name: string | null;
  phone: string | null;
  email: string | null;
  address: string | null;
  updated_at: string;
};

const demoCompanies: Company[] = [
  {
    id: "demo-1",
    name: "Atlas Medikal",
    display_name: null,
    phone: "+90 212 555 12 20",
    email: "satinalma@atlasmedikal.com",
    address: "Şişli, İstanbul",
    updated_at: "2026-08-02T10:42:00Z",
  },
  {
    id: "demo-2",
    name: "Nova Otomasyon",
    display_name: null,
    phone: "+90 216 555 33 10",
    email: "bilgi@novaotomasyon.com",
    address: "Ümraniye, İstanbul",
    updated_at: "2026-08-01T15:10:00Z",
  },
  {
    id: "demo-3",
    name: "Marmara Ambalaj",
    display_name: null,
    phone: "+90 262 555 08 05",
    email: "satis@marmaraambalaj.com",
    address: "Gebze, Kocaeli",
    updated_at: "2026-07-30T12:00:00Z",
  },
];

async function getCompanies(
  query: string,
  page: number,
): Promise<{
  companies: Company[];
  demo: boolean;
  total: number;
  hasMore: boolean;
}> {
  const pageSize = 50;
  const offset = (page - 1) * pageSize;
  const supabase = await createSupabaseServerClient();
  if (!supabase) {
    const normalized = query.toLocaleLowerCase("tr-TR");
    const companies = normalized
      ? demoCompanies.filter((company) =>
          [company.name, company.phone, company.email, company.address].some(
            (value) => value?.toLocaleLowerCase("tr-TR").includes(normalized),
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
  const query = params.q?.trim() ?? "";
  const parsedPage = Number.parseInt(params.page ?? "1", 10);
  const page = Number.isFinite(parsedPage) ? Math.max(parsedPage, 1) : 1;
  const { companies, demo, total, hasMore } = await getCompanies(query, page);
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
            ← Genel bakış
          </Link>
          <span className="eyebrow">MÜŞTERİ HAFIZASI</span>
          <h1>Müşteriler</h1>
          <p>Firma geçmişi, açık takipler ve yaklaşan ziyaretler.</p>
        </div>
        <div className="header-actions">
          <Link className="secondary-action" href="/import">
            Excel/CSV aktar
          </Link>
          <Link className="primary button-link" href="/customers/new">
            + Firma ekle
          </Link>
        </div>
      </header>
      {demo && (
        <div className="demo-notice">
          <strong>Demo verileri gösteriliyor.</strong> Supabase bağlantısı
          yapıldığında bu liste çalışma alanınızdaki gerçek kayıtları kullanır.
        </div>
      )}
      <form className="customer-toolbar" action="/customers">
        <label className="search-field">
          <span>⌕</span>
          <input
            aria-label="Müşteri ara"
            name="q"
            defaultValue={query}
            placeholder="Kısa ad, firma, telefon veya adres ara"
          />
        </label>
        <button type="submit">Ara</button>
        <span>{total} firma</span>
      </form>
      <section className="customer-table-wrap">
        <table className="customer-table">
          <thead>
            <tr>
              <th>Firma</th>
              <th>İletişim</th>
              <th>Konum</th>
              <th>Son güncelleme</th>
              <th>
                <span className="sr-only">İşlem</span>
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
                        .toLocaleUpperCase("tr-TR")}
                    </span>
                    <div>
                      <strong>{company.display_name ?? company.name}</strong>
                      <small>
                        {company.display_name
                          ? company.name
                          : "Müşteri hafıza kartı hazır"}
                      </small>
                    </div>
                  </div>
                </td>
                <td>
                  <strong>{company.phone ?? "—"}</strong>
                  <small>{company.email ?? "E-posta yok"}</small>
                </td>
                <td>{company.address ?? "Konum eklenmedi"}</td>
                <td>
                  {new Intl.DateTimeFormat("tr-TR", {
                    day: "numeric",
                    month: "short",
                    year: "numeric",
                  }).format(new Date(company.updated_at))}
                </td>
                <td>
                  <a
                    href={`/customers/${company.id}`}
                    aria-label={`${company.name} detayını aç`}
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
            <strong>Henüz müşteri yok</strong>
            <p>İlk firmanızı ekleyin veya Excel/CSV dosyasından içe aktarın.</p>
            <Link className="primary button-link" href="/customers/new">
              İlk firmayı ekle
            </Link>
          </div>
        )}
        {(page > 1 || hasMore) && (
          <nav className="customer-toolbar" aria-label="Müşteri sayfaları">
            {page > 1 ? (
              <Link className="secondary-action" href={pageHref(page - 1)}>
                ← Önceki
              </Link>
            ) : (
              <span />
            )}
            <span>Sayfa {page}</span>
            {hasMore && (
              <Link className="secondary-action" href={pageHref(page + 1)}>
                Sonraki →
              </Link>
            )}
          </nav>
        )}
      </section>
    </main>
  );
}
