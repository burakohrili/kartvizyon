import Link from "next/link";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { completeTask } from "./actions";

type Task = {
  id: string;
  title: string;
  status: string;
  due_at: string | null;
  source: string;
  company: { name: string } | null;
};

const demoTasks: Task[] = [
  {
    id: "demo-1",
    title: "Revize teklifi gönder",
    status: "open",
    due_at: "2026-08-07T09:00:00Z",
    source: "ai_follow_up",
    company: { name: "Atlas Medikal" },
  },
  {
    id: "demo-2",
    title: "Teknik demo tarihini netleştir",
    status: "open",
    due_at: "2026-08-09T09:00:00Z",
    source: "ai_follow_up",
    company: { name: "Atlas Medikal" },
  },
  {
    id: "demo-3",
    title: "Bakım sözleşmesini kontrol et",
    status: "completed",
    due_at: "2026-08-02T09:00:00Z",
    source: "manual",
    company: { name: "Nova Otomasyon" },
  },
];

async function getTasks() {
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
  const { tasks, demo } = await getTasks();
  const openTasks = tasks.filter((task) => task.status === "open");
  const completed = tasks.filter((task) => task.status === "completed");
  return (
    <main className="customers-page tasks-page">
      <header className="customers-header">
        <div>
          <Link href="/" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">TAKVİM VE TAKİPLER</span>
          <h1>Görevlerim</h1>
          <p>Onayladığın AI takipleri ve elle eklenen saha görevleri.</p>
        </div>
      </header>
      {demo && (
        <div className="demo-notice">
          <strong>Demo görevleri.</strong> Onaylanan ziyaret takipleri burada
          otomatik görünür.
        </div>
      )}
      <section className="task-columns">
        <div className="task-column">
          <header>
            <h2>Yaklaşan</h2>
            <span>{openTasks.length}</span>
          </header>
          {openTasks.map((task) => (
            <article key={task.id}>
              <div>
                <small>{task.company?.name ?? "Firma yok"}</small>
                <strong>{task.title}</strong>
                <time>
                  {task.due_at
                    ? new Intl.DateTimeFormat("tr-TR", {
                        dateStyle: "medium",
                      }).format(new Date(task.due_at))
                    : "Tarih yok"}
                </time>
              </div>
              {task.source === "ai_follow_up" && <em>AI · ONAYLI ZİYARET</em>}
              <form action={completeTask}>
                <input type="hidden" name="taskId" value={task.id} />
                <button>Tamamla</button>
              </form>
            </article>
          ))}
        </div>
        <div className="task-column completed-column">
          <header>
            <h2>Tamamlanan</h2>
            <span>{completed.length}</span>
          </header>
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
