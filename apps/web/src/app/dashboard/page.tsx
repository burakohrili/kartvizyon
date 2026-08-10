import Image from "next/image";
import Link from "next/link";
import { loadDashboard } from "@/lib/dashboard";

const nav = [
  { label: "Genel Bakış", href: "/dashboard" },
  { label: "Aktivite", href: "/activity" },
  { label: "Müşteriler", href: "/customers" },
  { label: "Harita", href: "/map" },
  { label: "Ziyaretler", href: "/visits" },
  { label: "Takvim", href: "/calendar" },
  { label: "Görevler", href: "/tasks" },
  { label: "Fırsatlar", href: "/opportunities" },
  { label: "Siparişler", href: "/orders" },
  { label: "Ürün ve Fiyatlar", href: "/products" },
  { label: "Raporlar", href: "/reports" },
  { label: "Formlar", href: "/forms" },
  { label: "Belgeler", href: "/documents" },
  { label: "Bildirimler", href: "/notifications" },
  { label: "Hesap Güvenliği", href: "/settings/security" },
  { label: "Paket ve Kullanım", href: "/settings/billing" },
  { label: "Entegrasyonlar", href: "/settings/integrations" },
  { label: "KVKK", href: "/settings/privacy" },
];

export default async function DashboardHome() {
  const dashboard = await loadDashboard();
  const now = new Date();
  const userName = String(dashboard.userName);
  const initials = userName
    .split(/\s+/)
    .slice(0, 2)
    .map((part: string) => part[0])
    .join("")
    .toLocaleUpperCase("tr-TR");

  return (
    <main className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <Image
            src="/brand/logo-mark.png"
            alt=""
            width={40}
            height={40}
            priority
          />
          <div>
            KartVizyon<small>AI saha hafızası</small>
          </div>
        </div>
        <nav aria-label="Ana menü">
          {nav.map((item, index) => (
            <a
              className={index === 0 ? "active" : ""}
              href={item.href}
              key={item.label}
            >
              {item.label}
            </a>
          ))}
        </nav>
        <Link href="/workspaces" className="workspace">
          <span>Çalışma alanı</span>
          <strong>{dashboard.workspaceName}</strong>
          <small>
            {dashboard.demo ? "Demo çalışma alanı" : "Aktif çalışma alanı"}
          </small>
        </Link>
      </aside>

      <section className="content">
        <header className="topbar">
          <div>
            <p>{now.toLocaleDateString("tr-TR", { dateStyle: "full" })}</p>
            <h1>Günaydın, {userName}</h1>
          </div>
          <div className="top-actions">
            <Link
              className="icon-button"
              aria-label="Bildirimler"
              href="/notifications"
            >
              ●
            </Link>
            <div className="avatar">{initials}</div>
          </div>
        </header>

        <section className="hero">
          <div>
            <span className="eyebrow">BUGÜNÜN SAHA ÖZETİ</span>
            <h2>
              Ekibiniz müşterileriyle
              <br />
              kaldığı yerden devam ediyor.
            </h2>
            <p>
              Onaylanmış ziyaretler, açık takipler ve yaklaşan görüşmeler tek
              görünümde.
            </p>
          </div>
          <Link className="primary button-link" href="/visits">
            + Ziyaret planla
          </Link>
        </section>

        <section className="metrics" aria-label="Günlük metrikler">
          <article>
            <span className="metric-icon navy">✓</span>
            <div>
              <small>Tamamlanan ziyaret</small>
              <strong>{dashboard.completedToday}</strong>
              <em>Yalnızca onaylanmış kayıtlar</em>
            </div>
          </article>
          <article>
            <span className="metric-icon yellow">!</span>
            <div>
              <small>Geciken takip</small>
              <strong>{dashboard.overdueTasks}</strong>
              <em className="warning">Açık ve tarihi geçmiş görevler</em>
            </div>
          </article>
          <article>
            <span className="metric-icon blue">◎</span>
            <div>
              <small>Onay bekleyen</small>
              <strong>{dashboard.pendingReview}</strong>
              <em>Kullanıcı incelemesi gerekli</em>
            </div>
          </article>
          <article>
            <span className="metric-icon green">↗</span>
            <div>
              <small>Veri kaynağı</small>
              <strong>{dashboard.demo ? "Demo" : "Canlı"}</strong>
              <em>Tenant ve rol kuralları etkin</em>
            </div>
          </article>
        </section>

        <section className="grid">
          <article className="panel activity-panel">
            <div className="panel-heading">
              <div>
                <span className="eyebrow">KURUMSAL HAFIZA</span>
                <h3>Son onaylanan ziyaretler</h3>
              </div>
              <Link className="link-button" href="/visits">
                Tümünü gör →
              </Link>
            </div>
            <div className="timeline">
              {dashboard.activities.map((activity) => (
                <div className="activity" key={activity.id}>
                  <span className="timeline-dot" />
                  <div>
                    <div className="activity-title">
                      <strong>{activity.company}</strong>
                      <time>
                        {new Date(activity.approvedAt).toLocaleString("tr-TR", {
                          dateStyle: "short",
                          timeStyle: "short",
                        })}
                      </time>
                    </div>
                    <p>{activity.summary}</p>
                    <small>{activity.representative} · Saha satış</small>
                  </div>
                </div>
              ))}
            </div>
          </article>

          <aside className="panel briefing">
            <span className="eyebrow">SIRADAKİ ZİYARET</span>
            {dashboard.nextVisit ? (
              <>
                <div className="brief-time">
                  {new Date(
                    dashboard.nextVisit.plannedStartAt,
                  ).toLocaleTimeString("tr-TR", {
                    hour: "2-digit",
                    minute: "2-digit",
                    timeZone: "Europe/Istanbul",
                  })}{" "}
                  <span>
                    {new Date(
                      dashboard.nextVisit.plannedStartAt,
                    ).toLocaleDateString("tr-TR", {
                      day: "2-digit",
                      month: "short",
                      timeZone: "Europe/Istanbul",
                    })}
                  </span>
                </div>
                <h3>{dashboard.nextVisit.company}</h3>
                {dashboard.nextVisit.address ? (
                  <p className="location">📍 {dashboard.nextVisit.address}</p>
                ) : null}
                <div className="memory">
                  <strong>Müşteri hafıza kartı</strong>
                  <p>
                    {dashboard.nextVisit.memorySummary ??
                      "Bu müşteri için henüz onaylı ziyaret özeti bulunmuyor."}
                  </p>
                  <ul>
                    <li>{dashboard.nextVisit.openTasks} açık takip</li>
                    <li>
                      {dashboard.nextVisit.sourceCount} onaylı ziyaret kaynağı
                    </li>
                  </ul>
                </div>
                <Link
                  className="secondary button-link"
                  href={`/customers/${dashboard.nextVisit.companyId}`}
                >
                  Ziyaret brifingini aç
                </Link>
                <small className="source">
                  {dashboard.nextVisit.sourceCount} onaylı kaynaktan hazırlandı
                </small>
              </>
            ) : (
              <>
                <h3>Planlı ziyaret bulunmuyor</h3>
                <p className="location">
                  Takvime yeni bir ziyaret eklediğinizde brifing burada görünür.
                </p>
                <Link className="secondary button-link" href="/calendar">
                  Ziyaret planla
                </Link>
              </>
            )}
          </aside>
        </section>

        <section className="review-banner">
          <div className="review-icon">AI</div>
          <div>
            <strong>
              {dashboard.pendingReview} AI özeti onayınızı bekliyor
            </strong>
            <p>
              Onaylamadan önce özetleri ve oluşturulan takipleri kontrol edin.
            </p>
          </div>
          <Link href="/visits">İncele</Link>
        </section>
      </section>
    </main>
  );
}
