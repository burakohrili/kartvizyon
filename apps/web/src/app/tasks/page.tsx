import Link from "next/link";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { completeTask } from "./actions";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";
import { formatDate } from "@/lib/i18n/locale";
import { getDemoRecords } from "@/lib/i18n/demo-records";

type Task = {
  id: string;
  title: string;
  status: string;
  due_at: string | null;
  source: string;
  company: { name: string } | null;
};

async function getTasks(locale: "en" | "tr") {
  const demo = getDemoRecords(locale);
  const demoTasks: Task[] = [
    {
      id: "demo-1",
      title: demo.tasks[0],
      status: "open",
      due_at: "2026-08-07T09:00:00Z",
      source: "ai_follow_up",
      company: { name: demo.companies[0] },
    },
    {
      id: "demo-2",
      title: demo.tasks[1],
      status: "open",
      due_at: "2026-08-09T09:00:00Z",
      source: "ai_follow_up",
      company: { name: demo.companies[0] },
    },
    {
      id: "demo-3",
      title: demo.tasks[2],
      status: "completed",
      due_at: "2026-08-02T09:00:00Z",
      source: "manual",
      company: { name: demo.companies[1] },
    },
  ];
  const supabase = await createSupabaseServerClient();
  if (!supabase) return { tasks: demoTasks, demo: true };
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { tasks: demoTasks, demo: true };
  const { data } = await supabase
    .from("tasks")
    .select("id,title,status,due_at,source,company:companies(name)")
    .eq("assigned_to", user.id)
    .order("due_at", { ascending: true, nullsFirst: false })
    .limit(200);
  return { tasks: (data as unknown as Task[] | null) ?? [], demo: false };
}

export default async function TasksPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).tasks;
  const { tasks, demo: isDemo } = await getTasks(locale);
  const openTasks = tasks.filter((task) => task.status === "open");
  const completed = tasks.filter((task) => task.status === "completed");
  return (
    <main className="customers-page tasks-page">
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
      </header>
      {isDemo && (
        <div className="demo-notice">
          <strong>{m.demoTitle}</strong> {m.demoBody}
        </div>
      )}
      <section className="task-columns">
        <div className="task-column">
          <header>
            <h2>{m.upcoming}</h2>
            <span>{openTasks.length}</span>
          </header>
          {openTasks.length === 0 && (
            <p className="empty-state">{m.allCaughtUp}</p>
          )}
          {openTasks.map((task) => (
            <article key={task.id}>
              <div>
                <small>{task.company?.name ?? m.noCompany}</small>
                <strong>{task.title}</strong>
                <time>
                  {task.due_at ? formatDate(task.due_at, locale) : m.noDate}
                </time>
              </div>
              {task.source === "ai_follow_up" && <em>{m.aiApprovedVisit}</em>}
              <form action={completeTask}>
                <input type="hidden" name="taskId" value={task.id} />
                <button>{m.complete}</button>
              </form>
            </article>
          ))}
        </div>
        <div className="task-column completed-column">
          <header>
            <h2>{m.completed}</h2>
            <span>{completed.length}</span>
          </header>
          {completed.length === 0 && (
            <p className="empty-state">{m.noCompletedTasks}</p>
          )}
          {completed.map((task) => (
            <article key={task.id}>
              <div>
                <small>{task.company?.name}</small>
                <strong>{task.title}</strong>
              </div>
              <b>✓</b>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
