import Link from "next/link";
import { notFound } from "next/navigation";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";
import { formatDate, formatDateTime } from "@/lib/i18n/locale";
import { getDemoRecords } from "@/lib/i18n/demo-records";

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

async function getCustomer(id: string, locale: "en" | "tr") {
  if (id.startsWith("demo-")) {
    const demo = getDemoRecords(locale);
    const contact = (index: number) => demo.contactNames[index].split(" ");
    const name =
      id === "demo-1"
        ? demo.companies[0]
        : id === "demo-2"
          ? demo.companies[1]
          : demo.companies[2];
    const firstContact = contact(0);
    const secondContact = contact(1);
    return {
      company: {
        id,
        name,
        address: locale === "en" ? "Istanbul" : "İstanbul",
        phone: "+90 212 555 12 20",
        email: "bilgi@firma.com",
      } satisfies Company,
      contacts: [
        {
          ...demoContacts[0],
          first_name: firstContact[0],
          last_name: firstContact.slice(1).join(" "),
          title: demo.contactTitles[0],
        },
        {
          ...demoContacts[1],
          first_name: secondContact[0],
          last_name: secondContact.slice(1).join(" "),
          title: demo.contactTitles[1],
        },
      ],
      tasks: demoTasks.map((task, index) => ({
        ...task,
        title: demo.tasks[index],
      })),
      memory: {
        summary: demo.customerSummary,
        open_promises: [demo.customerPromise],
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
  const locale = await getRequestLocale();
  const m = getMessages(locale).customerDetail;
  const data = await getCustomer(id, locale);
  if (!data) notFound();
  const { company, contacts, tasks, memory, lastVisit } = data;
  const lastVisitLabel = lastVisit?.approved_at
    ? formatDate(lastVisit.approved_at, locale)
    : null;
  return (
    <main className="form-page">
      <DemoBanner />
      <section className="customer-detail wide-detail">
        <div className="detail-top">
          <div>
            <Link href="/customers" className="back-link">
              {m.back}
            </Link>
            <span className="eyebrow">{m.eyebrow}</span>
            <h1>{company.name}</h1>
            <p>
              {company.address ?? m.locationMissing} ·{" "}
              {company.phone ?? m.phoneMissing}
            </p>
          </div>
          <Link
            className="primary button-link"
            href={`/visits?companyId=${id}`}
          >
            {m.recordVisit}
          </Link>
        </div>
        <div className="memory-detail">
          <strong>{m.nextVisitPrep}</strong>
          <p>{memory?.summary ?? m.memoryUnavailable}</p>
          <div>
            <span>
              {m.lastVisit}
              <strong>{lastVisitLabel ?? m.noLastVisit}</strong>
            </span>
            <span>
              {m.openFollowUps}
              <strong>{tasks.length}</strong>
            </span>
            <span>
              {m.sources}
              <strong>
                {memory?.source_visit_ids.length ?? 0} {m.approvedVisits}
              </strong>
            </span>
          </div>
        </div>
        <div className="customer-detail-grid">
          <section className="detail-panel">
            <div className="detail-heading">
              <h2>{m.contacts}</h2>
              <Link href={`/customers/${id}/contacts/new`}>{m.addContact}</Link>
            </div>
            {contacts.length === 0 ? (
              <p className="muted-empty">{m.noContacts}</p>
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
                    <small>{contact.title ?? m.noPosition}</small>
                    <p>{contact.phone ?? contact.email ?? m.noContactInfo}</p>
                  </div>
                </article>
              ))
            )}
          </section>
          <section className="detail-panel">
            <div className="detail-heading">
              <h2>{m.tasks}</h2>
              <button>{m.addTask}</button>
            </div>
            {tasks.length === 0 ? (
              <p className="muted-empty">{m.noTasks}</p>
            ) : (
              tasks.map((task) => (
                <article className="task-row" key={task.id}>
                  <input
                    type="checkbox"
                    aria-label={m.completeTask.replace("{task}", task.title)}
                  />
                  <div>
                    <strong>{task.title}</strong>
                    <small>
                      {task.due_at
                        ? formatDate(task.due_at, locale)
                        : m.noDueDate}
                    </small>
                  </div>
                </article>
              ))
            )}
          </section>
        </div>
        {memory && (
          <p className="memory-source-note">
            {m.memoryUpdated.replace(
              "{date}",
              formatDateTime(memory.generated_at, locale),
            )}
          </p>
        )}
      </section>
    </main>
  );
}
