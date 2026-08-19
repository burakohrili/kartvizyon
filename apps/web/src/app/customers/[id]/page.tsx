import Link from "next/link";
import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { DemoBanner } from "@/app/demo-banner";

type Company = {
  id?: string;
  name: string;
  address: string | null;
  phone: string | null;
  email: string | null;
};
type Contact = {
  id: string;
  first_name: string;
  last_name: string | null;
  title: string | null;
  phone: string | null;
  email: string | null;
};
type Task = { id: string; title: string; due_at: string | null };
type Memory = {
  summary: string;
  open_promises: unknown;
  source_visit_ids: string[];
  generated_at: string;
  stale_after: string;
};

const demoContacts: Contact[] = [
  {
    id: "c1",
    first_name: "Murat",
    last_name: "Aydın",
    title: "Satın Alma Müdürü",
    phone: "+90 532 555 19 23",
    email: "murat@firma.com",
  },
  {
    id: "c2",
    first_name: "Deniz",
    last_name: "Şen",
    title: "Teknik Müdür",
    phone: null,
    email: "deniz@firma.com",
  },
];
const demoTasks: Task[] = [
  { id: "t1", title: "Revize teklifi gönder", due_at: "2026-08-07T09:00:00Z" },
  {
    id: "t2",
    title: "Demo tarihini netleştir",
    due_at: "2026-08-09T09:00:00Z",
  },
];

async function getCustomer(id: string) {
  if (id.startsWith("demo-")) {
    const name =
      id === "demo-1"
        ? "Atlas Medikal"
        : id === "demo-2"
          ? "Nova Otomasyon"
          : "Marmara Ambalaj";
    return {
      company: {
        id,
        name,
        address: "İstanbul",
        phone: "+90 212 555 12 20",
        email: "bilgi@firma.com",
      } satisfies Company,
      contacts: demoContacts,
      tasks: demoTasks,
      memory: {
        summary:
          "Son görüşmede bakım paketi, garanti seçenekleri ve revize teklif tarihi konuşuldu. Satın alma müdürü teknik demo tarihini bekliyor.",
        open_promises: ["Revize teklif"],
        source_visit_ids: ["v1", "v2", "v3"],
        generated_at: "2026-08-02T10:42:00Z",
        stale_after: "2026-08-09T10:42:00Z",
      } satisfies Memory,
      lastVisit: { approved_at: "2026-07-13T10:00:00Z" },
    };
  }
  const supabase = await createSupabaseServerClient();
  if (!supabase) return null;
  const [
    companyResult,
    contactsResult,
    tasksResult,
    memoryResult,
    visitResult,
  ] = await Promise.all([
    supabase
      .from("companies")
      .select("id,name,address,phone,email")
      .eq("id", id)
      .single(),
    supabase
      .from("contacts")
      .select("id,first_name,last_name,title,phone,email")
      .eq("company_id", id)
      .order("created_at"),
    supabase
      .from("tasks")
      .select("id,title,due_at")
      .eq("company_id", id)
      .eq("status", "open")
      .order("due_at")
      .limit(5),
    supabase
      .from("customer_memory_cards")
      .select("summary,open_promises,source_visit_ids,generated_at,stale_after")
      .eq("company_id", id)
      .maybeSingle(),
    supabase
      .from("visits")
      .select("approved_at")
      .eq("company_id", id)
      .eq("status", "approved")
      .order("approved_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);
  if (!companyResult.data) return null;
  return {
    company: companyResult.data as Company,
    contacts: (contactsResult.data as Contact[] | null) ?? [],
    tasks: (tasksResult.data as Task[] | null) ?? [],
    memory: memoryResult.data as Memory | null,
    lastVisit: visitResult.data,
  };
}

export default async function CustomerDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const data = await getCustomer(id);
  if (!data) notFound();
  const { company, contacts, tasks, memory, lastVisit } = data;
  const lastVisitLabel = lastVisit?.approved_at
    ? new Intl.DateTimeFormat("tr-TR", { dateStyle: "medium" }).format(
        new Date(lastVisit.approved_at),
      )
    : null;
  return (
    <main className="form-page">
      <DemoBanner />
      <section className="customer-detail wide-detail">
        <div className="detail-top">
          <div>
            <Link href="/customers" className="back-link">
              ← Müşteriler
            </Link>
            <span className="eyebrow">MÜŞTERİ HAFIZA KARTI</span>
            <h1>{company.name}</h1>
            <p>
              {company.address ?? "Konum eklenmedi"} ·{" "}
              {company.phone ?? "Telefon eklenmedi"}
            </p>
          </div>
          <Link
            className="primary button-link"
            href={`/visits?companyId=${id}`}
          >
            + Ziyaret kaydet
          </Link>
        </div>
        <div className="memory-detail">
          <strong>Bir sonraki ziyarete hazırlık</strong>
          <p>
            {memory?.summary ??
              "Henüz onaylı ziyaret olmadığı için hafıza kartı oluşturulmadı."}
          </p>
          <div>
            <span>
              Son ziyaret
              <strong>{lastVisitLabel ?? "Henüz yok"}</strong>
            </span>
            <span>
              Açık takip<strong>{tasks.length}</strong>
            </span>
            <span>
              Kaynak
              <strong>
                {memory?.source_visit_ids.length ?? 0} onaylı ziyaret
              </strong>
            </span>
          </div>
        </div>
        <div className="customer-detail-grid">
          <section className="detail-panel">
            <div className="detail-heading">
              <h2>İlgili kişiler</h2>
              <Link href={`/customers/${id}/contacts/new`}>+ Kişi ekle</Link>
            </div>
            {contacts.length === 0 ? (
              <p className="muted-empty">İlgili kişi eklenmedi.</p>
            ) : (
              contacts.map((contact) => (
                <article className="contact-row" key={contact.id}>
                  <span>
                    {contact.first_name.slice(0, 1)}
                    {contact.last_name?.slice(0, 1)}
                  </span>
                  <div>
                    <strong>
                      {contact.first_name} {contact.last_name}
                    </strong>
                    <small>{contact.title ?? "Pozisyon eklenmedi"}</small>
                    <p>
                      {contact.phone ?? contact.email ?? "İletişim bilgisi yok"}
                    </p>
                  </div>
                </article>
              ))
            )}
          </section>
          <section className="detail-panel">
            <div className="detail-heading">
              <h2>Açık takipler</h2>
              <button>+ Takip ekle</button>
            </div>
            {tasks.length === 0 ? (
              <p className="muted-empty">Açık takip bulunmuyor.</p>
            ) : (
              tasks.map((task) => (
                <article className="task-row" key={task.id}>
                  <input
                    type="checkbox"
                    aria-label={`${task.title} görevini tamamla`}
                  />
                  <div>
                    <strong>{task.title}</strong>
                    <small>
                      {task.due_at
                        ? new Intl.DateTimeFormat("tr-TR", {
                            dateStyle: "medium",
                          }).format(new Date(task.due_at))
                        : "Tarih yok"}
                    </small>
                  </div>
                </article>
              ))
            )}
          </section>
        </div>
        {memory && (
          <p className="memory-source-note">
            Hafıza kartı{" "}
            {new Intl.DateTimeFormat("tr-TR", {
              dateStyle: "medium",
              timeStyle: "short",
            }).format(new Date(memory.generated_at))}{" "}
            tarihinde yalnızca onaylı kayıtlardan yenilendi.
          </p>
        )}
      </section>
    </main>
  );
}
