"use client";

import { useCallback, useEffect, useState } from "react";

type JsonRecord = Record<string, unknown>;

function Status({ message }: { message: string }) {
  return message ? (
    <p className="form-message" role="status">
      {message}
    </p>
  ) : null;
}

export function BillingPanel({ enabled }: { enabled: boolean }) {
  const [data, setData] = useState<JsonRecord | null>(null);
  const [message, setMessage] = useState("");
  useEffect(() => {
    if (!enabled) return;
    const controller = new AbortController();
    void fetch("/api/settings/billing", { signal: controller.signal })
      .then((response) => Promise.all([response.ok, response.json()]))
      .then(([ok, result]) => {
        if (ok) setData(result);
        else setMessage(result.error ?? "Kullanım bilgisi alınamadı.");
      })
      .catch((error: Error) => {
        if (error.name !== "AbortError")
          setMessage("Kullanım bilgisi alınamadı.");
      });
    return () => controller.abort();
  }, [enabled]);
  if (!enabled)
    return (
      <div className="demo-notice">
        Canlı paket bilgisi için Supabase oturumu gerekir.
      </div>
    );
  if (!data)
    return <Status message={message || "Kullanım bilgisi yükleniyor…"} />;
  const plans = (data.plans as JsonRecord[]) ?? [];
  const subscription = data.subscription as JsonRecord | null;
  const usage = (data.usage as JsonRecord) ?? {};
  return (
    <div className="settings-stack">
      <section className="settings-summary">
        <article>
          <small>Aktif paket</small>
          <strong>
            {String((subscription?.plan as JsonRecord)?.name ?? "Başlangıç")}
          </strong>
        </article>
        <article>
          <small>Kullanılan koltuk</small>
          <strong>{String(data.seatsUsed ?? 0)}</strong>
        </article>
        <article>
          <small>AI ses</small>
          <strong>{Math.ceil(Number(usage.audio_seconds ?? 0) / 60)} dk</strong>
        </article>
        <article>
          <small>Dosya alanı</small>
          <strong>
            {(Number(usage.storage_bytes ?? 0) / 1048576).toFixed(1)} MB
          </strong>
        </article>
      </section>
      <section className="plan-grid">
        {plans.map((plan) => (
          <article key={String(plan.id)} className="settings-card">
            <h2>{String(plan.name)}</h2>
            <strong>
              {Number(plan.monthly_price_try)
                ? `${Number(plan.monthly_price_try).toLocaleString("tr-TR")} ₺/ay`
                : "Teklif alın"}
            </strong>
            <p>
              {String(plan.seat_limit)} kullanıcı ·{" "}
              {String(plan.monthly_ai_minutes)} AI dakika
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
        Paket değişikliği ödeme sağlayıcısı bağlandıktan sonra etkinleşir; bu
        ekran kota ve tüketimi güvenli biçimde izler.
      </p>
    </div>
  );
}

export function IntegrationsPanel({
  workspaceId,
}: {
  workspaceId: string | null;
}) {
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
    } else setMessage(result.error ?? "Entegrasyonlar alınamadı.");
  }, [workspaceId]);
  useEffect(() => {
    if (!workspaceId) return;
    const controller = new AbortController();
    void fetch("/api/settings/integrations", { signal: controller.signal })
      .then((response) => Promise.all([response.ok, response.json()]))
      .then(([ok, result]) => {
        if (ok) {
          setCredentials(result.credentials ?? []);
          setWebhooks(result.webhooks ?? []);
        } else setMessage(result.error ?? "Entegrasyonlar alınamadı.");
      })
      .catch((error: Error) => {
        if (error.name !== "AbortError")
          setMessage("Entegrasyonlar alınamadı.");
      });
    return () => controller.abort();
  }, [workspaceId]);
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
      setMessage("Anahtar yalnızca bu kez gösterilir.");
      await load();
    } else setMessage(result.error ?? "Anahtar oluşturulamadı.");
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
      setMessage("İmzalama sırrı yalnızca bu kez gösterilir.");
      await load();
    } else setMessage(result.error ?? "Webhook oluşturulamadı.");
  }
  async function revoke(kind: string, id: unknown) {
    const response = await fetch("/api/settings/integrations", {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ kind, id }),
    });
    if (response.ok) await load();
  }
  if (!workspaceId)
    return (
      <div className="demo-notice">
        Entegrasyon yönetimi için Supabase oturumu gerekir.
      </div>
    );
  return (
    <div className="settings-stack">
      {secret && (
        <div className="secret-once">
          <strong>Şimdi güvenli yere kaydedin</strong>
          <code>{secret}</code>
        </div>
      )}
      <Status message={message} />
      <div className="settings-columns">
        <form action={createCredential} className="settings-card">
          <h2>API anahtarı</h2>
          <label>
            Ad
            <input name="name" required minLength={2} />
          </label>
          <button className="primary">Salt okunur anahtar üret</button>
        </form>
        <form action={createWebhook} className="settings-card">
          <h2>Webhook</h2>
          <label>
            Ad
            <input name="name" required minLength={2} />
          </label>
          <label>
            HTTPS adresi
            <input name="url" type="url" pattern="https://.*" required />
          </label>
          <button className="primary">Webhook ekle</button>
        </form>
      </div>
      <section className="settings-card">
        <h2>Etkin kimlik bilgileri</h2>
        {credentials.map((item) => (
          <p key={String(item.id)}>
            <code>{String(item.token_prefix)}…</code> {String(item.name)}{" "}
            <button onClick={() => void revoke("api_credential", item.id)}>
              İptal et
            </button>
          </p>
        ))}
      </section>
      <section className="settings-card">
        <h2>Webhook uçları</h2>
        {webhooks.map((item) => (
          <p key={String(item.id)}>
            <strong>{String(item.name)}</strong> {String(item.url)}{" "}
            <button onClick={() => void revoke("webhook", item.id)}>
              Devre dışı bırak
            </button>
          </p>
        ))}
      </section>
    </div>
  );
}

export function PrivacyPanel({ workspaceId }: { workspaceId: string | null }) {
  const [data, setData] = useState<JsonRecord>({ consents: [], requests: [] });
  const [message, setMessage] = useState("");
  const load = useCallback(async () => {
    if (!workspaceId) return;
    const response = await fetch("/api/settings/privacy");
    const result = await response.json();
    if (response.ok) setData(result);
    else setMessage(result.error ?? "Veri hakları yüklenemedi.");
  }, [workspaceId]);
  useEffect(() => {
    if (!workspaceId) return;
    const controller = new AbortController();
    void fetch("/api/settings/privacy", { signal: controller.signal })
      .then((response) => Promise.all([response.ok, response.json()]))
      .then(([ok, result]) => {
        if (ok) setData(result);
        else setMessage(result.error ?? "Veri hakları yüklenemedi.");
      })
      .catch((error: Error) => {
        if (error.name !== "AbortError")
          setMessage("Veri hakları yüklenemedi.");
      });
    return () => controller.abort();
  }, [workspaceId]);
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
    else setMessage("Tercih kaydedilemedi.");
  }
  async function createRequest(kind: "export" | "deletion") {
    const response = await fetch("/api/settings/privacy", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ workspaceId, kind }),
    });
    const result = await response.json();
    setMessage(
      response.ok
        ? "Talebiniz alındı ve audit kaydına işlendi."
        : (result.error ?? "Talep alınamadı."),
    );
    if (response.ok) await load();
  }
  if (!workspaceId)
    return (
      <div className="demo-notice">
        KVKK talepleri için Supabase oturumu gerekir.
      </div>
    );
  const options = [
    ["product_analytics", "Ürün analitiği"],
    ["ai_processing", "AI ile not işleme"],
    ["email_notifications", "E-posta bildirimleri"],
  ];
  return (
    <div className="settings-stack">
      <section className="settings-card">
        <h2>Açık rıza tercihleri</h2>
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
        <h2>Veri hakları</h2>
        <p>
          Dışa aktarma ve silme talepleri 30 günlük yasal operasyon süresiyle
          izlenir.
        </p>
        <div className="button-row">
          <button onClick={() => void createRequest("export")}>
            Verilerimi dışa aktar
          </button>
          <button
            className="danger"
            onClick={() => void createRequest("deletion")}
          >
            Silme talebi oluştur
          </button>
        </div>
      </section>
      <Status message={message} />
      <section className="settings-card">
        <h2>Taleplerim</h2>
        {((data.requests as JsonRecord[]) ?? []).map((item) => (
          <p key={String(item.id)}>
            {item.kind === "export" ? "Dışa aktarma" : "Silme"} ·{" "}
            <strong>{String(item.status)}</strong> ·{" "}
            {new Date(String(item.requested_at)).toLocaleDateString("tr-TR")}
            {item.kind === "export" && item.status === "ready" ? (
              <>
                {" "}
                ·{" "}
                <a href={`/api/settings/privacy/export/${String(item.id)}`}>
                  İndir
                </a>
              </>
            ) : null}
          </p>
        ))}
      </section>
    </div>
  );
}
