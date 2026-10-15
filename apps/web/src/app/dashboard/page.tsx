import Image from "next/image";
import Link from "next/link";
import { loadDashboard } from "@/lib/dashboard";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import {
  formatDate,
  formatDateTime,
  formatNumber,
  intlLocale,
} from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function DashboardHome() {
  const [dashboard, locale] = await Promise.all([
    loadDashboard(),
    getRequestLocale(),
  ]);
  const m = getMessages(locale).dashboard;
  const nav = [
    { label: m.overview, href: "/dashboard" },
    { label: m.activity, href: "/activity" },
    { label: m.customers, href: "/customers" },
    { label: m.map, href: "/map" },
    { label: m.visits, href: "/visits" },
    { label: m.calendar, href: "/calendar" },
    { label: m.tasks, href: "/tasks" },
    { label: m.opportunities, href: "/opportunities" },
    { label: m.orders, href: "/orders" },
    { label: m.products, href: "/products" },
    { label: m.reports, href: "/reports" },
    { label: m.forms, href: "/forms" },
    { label: m.documents, href: "/documents" },
    { label: m.notifications, href: "/notifications" },
    { label: m.security, href: "/settings/security" },
    { label: m.billing, href: "/settings/billing" },
    { label: m.integrations, href: "/settings/integrations" },
    { label: m.privacy, href: "/settings/privacy" },
  ];
  const now = new Date();
  const userName = String(dashboard.userName);
  const initials = userName
    .split(/\s+/)
    .slice(0, 2)
    .map((part: string) => part[0])
    .join("")
    .toLocaleUpperCase(intlLocale(locale));

  return (
    <main className="app-shell">
      <DemoBanner />
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
            KartVizyon<small>{m.brandSubtitle}</small>
          </div>
        </div>
        <nav aria-label={m.navigation}>
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
          <span>{m.workspace}</span>
          <strong>{dashboard.workspaceName}</strong>
          <small>{dashboard.demo ? m.demoWorkspace : m.activeWorkspace}</small>
        </Link>
      </aside>

      <section className="content">
        <header className="topbar">
          <div>
            <p>{formatDate(now, locale, { dateStyle: "full" })}</p>
            <h1>{m.welcome.replace("{name}", userName)}</h1>
          </div>
          <div className="top-actions">
            <Link
              className="icon-button"
              aria-label={m.notifications}
              href="/notifications"
            >
              ●
            </Link>
            <div className="avatar">{initials}</div>
          </div>
        </header>

        <section className="hero">
          <div>
            <span className="eyebrow">{m.today}</span>
            <h2>
              {m.heroTitle.split("\n")[0]}
              <br />
              {m.heroTitle.split("\n")[1]}
            </h2>
            <p>{m.heroBody}</p>
          </div>
          <Link className="primary button-link" href="/visits">
            {m.planVisit}
          </Link>
        </section>

        <section className="metrics" aria-label={m.dailyMetrics}>
          <article>
            <span className="metric-icon navy">✓</span>
            <div>
              <small>{m.completedVisits}</small>
              <strong>{dashboard.completedToday}</strong>
              <em>{m.approvedOnly}</em>
            </div>
          </article>
          <article>
            <span className="metric-icon yellow">!</span>
            <div>
              <small>{m.overdueFollowUps}</small>
              <strong>{dashboard.overdueTasks}</strong>
              <em className="warning">{m.openPastDue}</em>
            </div>
          </article>
          <article>
            <span className="metric-icon blue">◎</span>
            <div>
              <small>{m.pendingReview}</small>
              <strong>{dashboard.pendingReview}</strong>
              <em>{m.userReviewRequired}</em>
            </div>
          </article>
          <article>
            <span className="metric-icon green">↗</span>
            <div>
              <small>{m.dataSource}</small>
              <strong>{dashboard.demo ? m.demo : m.live}</strong>
              <em>{m.tenantRules}</em>
            </div>
          </article>
        </section>

        <section className="grid">
          <article className="panel activity-panel">
            <div className="panel-heading">
              <div>
                <span className="eyebrow">{m.companyMemory}</span>
                <h3>{m.recentVisits}</h3>
              </div>
              <Link className="link-button" href="/visits">
                {m.seeAll}
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
                        {formatDateTime(activity.approvedAt, locale, {
                          dateStyle: "short",
                          timeStyle: "short",
                        })}
                      </time>
                    </div>
                    <p>{activity.summary}</p>
                    <small>
                      {activity.representative} · {m.fieldSales}
                    </small>
                  </div>
                </div>
              ))}
            </div>
          </article>

          <aside className="panel briefing">
            <span className="eyebrow">{m.nextVisit}</span>
            {dashboard.nextVisit ? (
              <>
                <div className="brief-time">
                  {new Intl.DateTimeFormat(intlLocale(locale), {
                    hour: "2-digit",
                    minute: "2-digit",
                    timeZone: "Europe/Istanbul",
                  }).format(new Date(dashboard.nextVisit.plannedStartAt))}{" "}
                  <span>
                    {formatDate(dashboard.nextVisit.plannedStartAt, locale, {
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
                  <strong>{m.customerMemory}</strong>
                  <p>
                    {dashboard.nextVisit.memorySummary ?? m.noApprovedSummary}
                  </p>
                  <ul>
                    <li>
                      {formatNumber(dashboard.nextVisit.openTasks, locale)}{" "}
                      {m.openFollowUps}
                    </li>
                    <li>
                      {dashboard.nextVisit.sourceCount} {m.approvedVisitSources}
                    </li>
                  </ul>
                </div>
                <Link
                  className="secondary button-link"
                  href={`/customers/${dashboard.nextVisit.companyId}`}
                >
                  {m.openBriefing}
                </Link>
                <small className="source">
                  {m.preparedSources.replace(
                    "{count}",
                    String(dashboard.nextVisit.sourceCount),
                  )}
                </small>
              </>
            ) : (
              <>
                <h3>{m.noPlannedVisits}</h3>
                <p className="location">{m.addVisitForBriefing}</p>
                <Link className="secondary button-link" href="/calendar">
                  {m.planVisit}
                </Link>
              </>
            )}
          </aside>
        </section>

        <section className="review-banner">
          <div className="review-icon">AI</div>
          <div>
            <strong>
              {dashboard.pendingReview} {m.reviewSummary}
            </strong>
            <p>{m.reviewBeforeApproval}</p>
          </div>
          <Link href="/visits">{m.review}</Link>
        </section>
      </section>
    </main>
  );
}
