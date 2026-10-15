"use client";

import { useCallback, useEffect, useState } from "react";
import { IAP_INDIVIDUAL_MONTHLY_TRY } from "@/lib/pricing";
import { getMessages } from "@/lib/i18n/messages";
import type { AppLocale } from "@/lib/i18n/locale";
import { formatCurrency, formatNumber } from "@/lib/i18n/locale";

type JsonRecord = Record<string, unknown>;

function Status({ message }: { message: string }) {
  return message ? (
    <p className="form-message" role="status">
      {message}
    </p>
  ) : null;
}

export function BillingPanel({
  enabled,
  locale,
}: {
  enabled: boolean;
  locale: AppLocale;
}) {
  const m = getMessages(locale).settings.billing;
  const [data, setData] = useState<JsonRecord | null>(null);
  const [loadedAt, setLoadedAt] = useState<number | null>(null);
  const [message, setMessage] = useState("");
  useEffect(() => {
    if (!enabled) return;
    const controller = new AbortController();
    void fetch("/api/settings/billing", { signal: controller.signal })
      .then((response) => Promise.all([response.ok, response.json()]))
      .then(([ok, result]) => {
        if (ok) {
          setData(result);
          setLoadedAt(Date.now());
        } else setMessage(m.loadFailed);
      })
      .catch((error: Error) => {
        if (error.name !== "AbortError") setMessage(m.loadFailed);
      });
    return () => controller.abort();
  }, [enabled, m.loadFailed]);
  if (!enabled) return <div className="demo-notice">{m.demoNotice}</div>;
  if (!data || loadedAt === null)
    return <Status message={message || m.loading} />;
  const plans = (data.plans as JsonRecord[]) ?? [];
  const entitlement = data.entitlement as JsonRecord;
  const limits = entitlement.limits as JsonRecord;
  const daysLeft = Math.max(
    0,
    Math.ceil(
      (Date.parse(String(entitlement.trialEndsAt)) - loadedAt) / 86400000,
    ),
  );
  const usage = (data.usage as JsonRecord) ?? {};
  return (
    <div className="settings-stack">
      <p role="status">
        {entitlement.readOnly
          ? m.readOnly
          : entitlement.trialActive
            ? daysLeft <= 1
              ? m.trialLastDay
              : m.trialDays.replace("{days}", formatNumber(daysLeft, locale))
            : m.active}
      </p>
      <section className="settings-summary">
        <article>
          <small>{m.activePlan}</small>
          <strong>{String(entitlement.planName)}</strong>
        </article>
        <article>
          <small>{m.seatsUsed}</small>
          <strong>{String(data.seatsUsed ?? 0)}</strong>
        </article>
        <article>
          <small>AI ses</small>
          <strong>
            {formatNumber(Number(usage.audio_seconds ?? 0) / 60, locale)} /{" "}
            {String(limits.aiMinutes)} {m.minutes}
          </strong>
        </article>
        <article>
          <small>{m.cardScans}</small>
          <strong>
            {formatNumber(Number(usage.ocr ?? 0), locale)} /{" "}
            {String(limits.ocr ?? m.unlimited)}
          </strong>
        </article>
        <article>
          <small>{m.aiSummaries}</small>
          <strong>
            {formatNumber(Number(usage.ai_summary ?? 0), locale)} /{" "}
            {formatNumber(Number(limits.aiSummaries), locale)}
          </strong>
        </article>
      </section>
      <section className="plan-grid">
        {plans.map((plan) => (
          <article key={String(plan.id)} className="settings-card">
            <h2>{String(plan.name)}</h2>
            <strong>
              {Number(plan.monthly_price_try)
                ? `${formatCurrency(Number(plan.monthly_price_try), "TRY", locale)}/${locale === "en" ? "month" : "ay"}`
                : m.getQuote}
            </strong>
            <p>
              {formatNumber(Number(plan.seat_limit), locale)} {m.users} ·{" "}
              {formatNumber(Number(plan.monthly_ai_minutes), locale)}{" "}
              {m.aiMinutes}
            </p>
            <ul>
              {((plan.features as string[]) ?? []).map((feature) => (
                <li key={feature}>{feature}</li>
              ))}
            </ul>
          </article>
        ))}
      </section>
      <p className="muted">
        {m.individualNote.replace(
          "{price}",
          formatCurrency(IAP_INDIVIDUAL_MONTHLY_TRY, "TRY", locale),
        )}
      </p>
    </div>
  );
}

export function IntegrationsPanel({
  workspaceId,
  locale,
}: {
  workspaceId: string | null;
  locale: AppLocale;
}) {
  const m = getMessages(locale).settings.integrations;
  const [credentials, setCredentials] = useState<JsonRecord[]>([]);
  const [webhooks, setWebhooks] = useState<JsonRecord[]>([]);
  const [secret, setSecret] = useState("");
  const [message, setMessage] = useState("");
  const load = useCallback(async () => {
    if (!workspaceId) return;
    const response = await fetch("/api/settings/integrations");
    const result = await response.json();
    if (response.ok) {
      setCredentials(result.credentials ?? []);
      setWebhooks(result.webhooks ?? []);
    } else setMessage(m.loadFailed);
  }, [workspaceId, m.loadFailed]);
  useEffect(() => {
    if (!workspaceId) return;
    const controller = new AbortController();
    void fetch("/api/settings/integrations", { signal: controller.signal })
      .then((response) => Promise.all([response.ok, response.json()]))
      .then(([ok, result]) => {
        if (ok) {
          setCredentials(result.credentials ?? []);
          setWebhooks(result.webhooks ?? []);
        } else setMessage(m.loadFailed);
      })
      .catch((error: Error) => {
        if (error.name !== "AbortError") setMessage(m.loadFailed);
      });
    return () => controller.abort();
  }, [workspaceId, m.loadFailed]);
  async function createCredential(formData: FormData) {
    const response = await fetch("/api/settings/integrations", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        kind: "api_credential",
        data: {
          workspaceId,
          name: formData.get("name"),
          scopes: ["customers:read", "visits:read", "reports:read"],
        },
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setSecret(result.secret);
      setMessage(m.keyShownOnce);
      await load();
    } else setMessage(m.keyCreateFailed);
  }
  async function createWebhook(formData: FormData) {
    const response = await fetch("/api/settings/integrations", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        kind: "webhook",
        data: {
          workspaceId,
          name: formData.get("name"),
          url: formData.get("url"),
          events: ["visit.approved", "task.completed", "order.approved"],
        },
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setSecret(result.secret);
      setMessage(m.secretShownOnce);
      await load();
    } else setMessage(m.webhookCreateFailed);
  }
  async function revoke(kind: string, id: unknown) {
    const response = await fetch("/api/settings/integrations", {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ kind, id }),
    });
    if (response.ok) await load();
  }
  if (!workspaceId) return <div className="demo-notice">{m.demoNotice}</div>;
  return (
    <div className="settings-stack">
      {secret && (
        <div className="secret-once">
          <strong>{m.saveSecret}</strong>
          <code>{secret}</code>
        </div>
      )}
      <Status message={message} />
      <div className="settings-columns">
        <form action={createCredential} className="settings-card">
          <h2>{m.apiKey}</h2>
          <label>
            {m.name}
            <input name="name" required minLength={2} />
          </label>
          <button className="primary">{m.createReadOnlyKey}</button>
        </form>
        <form action={createWebhook} className="settings-card">
          <h2>{m.webhook}</h2>
          <label>
            {m.name}
            <input name="name" required minLength={2} />
          </label>
          <label>
            {m.httpsUrl}
            <input name="url" type="url" pattern="https://.*" required />
          </label>
          <button className="primary">{m.addWebhook}</button>
        </form>
      </div>
      <section className="settings-card">
        <h2>{m.activeCredentials}</h2>
        {credentials.map((item) => (
          <p key={String(item.id)}>
            <code>{String(item.token_prefix)}…</code> {String(item.name)}{" "}
            <button onClick={() => void revoke("api_credential", item.id)}>
              {m.revoke}
            </button>
          </p>
        ))}
      </section>
      <section className="settings-card">
        <h2>{m.webhookEndpoints}</h2>
        {webhooks.map((item) => (
          <p key={String(item.id)}>
            <strong>{String(item.name)}</strong> {String(item.url)}{" "}
            <button onClick={() => void revoke("webhook", item.id)}>
              {m.disable}
            </button>
          </p>
        ))}
      </section>
    </div>
  );
}

export function PrivacyPanel({
  workspaceId,
  locale,
}: {
  workspaceId: string | null;
  locale: AppLocale;
}) {
  const m = getMessages(locale).settings.privacy;
  const [data, setData] = useState<JsonRecord>({ consents: [], requests: [] });
  const [message, setMessage] = useState("");
  const load = useCallback(async () => {
    if (!workspaceId) return;
    const response = await fetch("/api/settings/privacy");
    const result = await response.json();
    if (response.ok) setData(result);
    else setMessage(m.loadFailed);
  }, [workspaceId, m.loadFailed]);
  useEffect(() => {
    if (!workspaceId) return;
    const controller = new AbortController();
    void fetch("/api/settings/privacy", { signal: controller.signal })
      .then((response) => Promise.all([response.ok, response.json()]))
      .then(([ok, result]) => {
        if (ok) setData(result);
        else setMessage(m.loadFailed);
      })
      .catch((error: Error) => {
        if (error.name !== "AbortError") setMessage(m.loadFailed);
      });
    return () => controller.abort();
  }, [workspaceId, m.loadFailed]);
  const consentMap = new Map(
    ((data.consents as JsonRecord[]) ?? []).map((item) => [
      item.purpose,
      item.granted,
    ]),
  );
  async function updateConsent(purpose: string, granted: boolean) {
    const response = await fetch("/api/settings/privacy", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ workspaceId, purpose, granted }),
    });
    if (response.ok) await load();
    else setMessage(m.preferenceSaveFailed);
  }
  async function createRequest(kind: "export" | "deletion") {
    const response = await fetch("/api/settings/privacy", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ workspaceId, kind }),
    });
    const result = await response.json();
    setMessage(response.ok ? m.requestReceived : m.requestFailed);
    if (response.ok) await load();
  }
  if (!workspaceId) return <div className="demo-notice">{m.demoNotice}</div>;
  const options = [
    ["product_analytics", m.analytics],
    ["ai_processing", m.aiProcessing],
    ["email_notifications", m.emailNotifications],
  ];
  return (
    <div className="settings-stack">
      <section className="settings-card">
        <h2>{m.consentTitle}</h2>
        {options.map(([purpose, label]) => (
          <label className="consent-row" key={purpose}>
            <span>{label}</span>
            <input
              type="checkbox"
              checked={Boolean(consentMap.get(purpose))}
              onChange={(event) =>
                void updateConsent(purpose, event.target.checked)
              }
            />
          </label>
        ))}
      </section>
      <section className="settings-card">
        <h2>{m.dataRights}</h2>
        <p>{m.rightsNotice}</p>
        <div className="button-row">
          <button onClick={() => void createRequest("export")}>
            {m.export}
          </button>
          <button
            className="danger"
            onClick={() => void createRequest("deletion")}
          >
            {m.createDeletion}
          </button>
        </div>
      </section>
      <Status message={message} />
      <section className="settings-card">
        <h2>{m.myRequests}</h2>
        {((data.requests as JsonRecord[]) ?? []).map((item) => (
          <p key={String(item.id)}>
            {item.kind === "export" ? m.exportLabel : m.deletionLabel} ·{" "}
            <strong>
              {m.statuses[String(item.status) as keyof typeof m.statuses] ??
                m.statuses.unknown}
            </strong>{" "}
            ·{" "}
            {new Intl.DateTimeFormat(locale === "en" ? "en-US" : "tr-TR", {
              dateStyle: "medium",
            }).format(new Date(String(item.requested_at)))}
            {item.resolution_note ? ` · ${String(item.resolution_note)}` : ""}
            {item.kind === "export" && item.status === "ready" ? (
              <>
                {" "}
                ·{" "}
                <a href={`/api/settings/privacy/export/${String(item.id)}`}>
                  {m.download}
                </a>
              </>
            ) : null}
          </p>
        ))}
      </section>
    </div>
  );
}
