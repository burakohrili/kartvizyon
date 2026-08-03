import { createSupabaseServerClient } from "@/lib/supabase/server";
import Link from "next/link";

type Company = {
  id: string;
  name: string;
  phone: string | null;
  email: string | null;
  address: string | null;
  updated_at: string;
};

const demoCompanies: Company[] = [
  {
    id: "demo-1",
    name: "Atlas Medikal",
    phone: "+90 212 555 12 20",
    email: "satinalma@atlasmedikal.com",
    address: "Şişli, İstanbul",
    updated_at: "2026-08-02T10:42:00Z",
  },
  {
    id: "demo-2",
    name: "Nova Otomasyon",
    phone: "+90 216 555 33 10",
    email: "bilgi@novaotomasyon.com",
    address: "Ümraniye, İstanbul",
    updated_at: "2026-08-01T15:10:00Z",
  },
  {
    id: "demo-3",
    name: "Marmara Ambalaj",
    phone: "+90 262 555 08 05",
    email: "satis@marmaraambalaj.com",
    address: "Gebze, Kocaeli",
    updated_at: "2026-07-30T12:00:00Z",
  },
];

async function getCompanies(): Promise<{
  companies: Company[];
  demo: boolean;
}> {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return { companies: demoCompanies, demo: true };
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { companies: demoCompanies, demo: true };
  const { data: workspaces } = await supabase
    .from("workspaces")
    .select("id")
    .limit(1);
  const workspaceId = workspaces?.[0]?.id;
  if (!workspaceId) return { companies: [], demo: false };
  const { data } = await supabase
    .from("companies")
    .select("id,name,phone,email,address,updated_at")
    .eq("workspace_id", workspaceId)
    .is("archived_at", null)
    .order("updated_at", { ascending: false });
  return { companies: (data as Company[] | null) ?? [], demo: false };
}

export default async function CustomersPage() {
  const { companies, demo } = await getCompanies();
  return (
    <main className="customers-page">
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
      <section className="customer-toolbar">
        <label className="search-field">
          <span>⌕</span>
          <input
            aria-label="Müşteri ara"
            placeholder="Firma, kişi veya telefon ara"
          />
        </label>
        <button>Filtreler</button>
        <span>{companies.length} firma</span>
      </section>
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
                      {company.name.slice(0, 2).toLocaleUpperCase("tr-TR")}
                    </span>
                    <div>
                      <strong>{company.name}</strong>
                      <small>Müşteri hafıza kartı hazır</small>
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
      </section>
    </main>
  );
}
