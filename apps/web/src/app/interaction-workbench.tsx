"use client";

import { useState } from "react";

type Item = Record<string, unknown>;

export function ActivityFeed({
  initialVisits,
  initialComments,
}: {
  initialVisits: Item[];
  initialComments: Item[];
}) {
  const [comments, setComments] = useState(initialComments);
  const [message, setMessage] = useState("");
  async function comment(visitId: string, formData: FormData) {
    const body = String(formData.get("body") ?? "");
    const response = await fetch("/api/activity/comments", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ visitId, body }),
    });
    const result = await response.json();
    if (response.ok) {
      setComments((current) => [
        ...current,
        {
          id: result.id,
          visit_id: visitId,
          body,
          created_at: new Date().toISOString(),
          author: { full_name: "Siz" },
        },
      ]);
      setMessage("Yorum eklendi ve temsilciye bildirildi.");
    } else setMessage(result.error ?? "Yorum eklenemedi.");
  }
  return (
    <section className="activity-feed-full">
      {message && <p className="form-message">{message}</p>}
      {initialVisits.map((visit) => {
        const company = visit.company as { name?: string } | null;
        const representative = visit.representative as {
          full_name?: string;
        } | null;
        const summary = visit.ai_summary as { summary?: string } | null;
        const visitComments = comments.filter(
          (item) => item.visit_id === visit.id,
        );
        return (
          <article key={String(visit.id)}>
            <header>
              <div>
                <strong>{company?.name ?? "Firma"}</strong>
                <small>{representative?.full_name ?? "Saha temsilcisi"}</small>
              </div>
              <time>
                {new Date(String(visit.approved_at)).toLocaleString("tr-TR")}
              </time>
            </header>
            <p>{summary?.summary ?? "Onaylı ziyaret"}</p>
            <div className="activity-comments">
              {visitComments.map((item) => {
                const author = item.author as { full_name?: string } | null;
                return (
                  <blockquote key={String(item.id)}>
                    <strong>{author?.full_name ?? "Kullanıcı"}</strong>
                    {String(item.body)}
                  </blockquote>
                );
              })}
            </div>
            <form
              action={comment.bind(null, String(visit.id))}
              className="inline-comment-form"
            >
              <input
                name="body"
                aria-label="Yönetici yorumu"
                placeholder="Yorum veya yönlendirme ekleyin"
                required
                maxLength={2000}
              />
              <button>Yorum ekle</button>
            </form>
          </article>
        );
      })}
    </section>
  );
}

export function NotificationCenter({ initialItems }: { initialItems: Item[] }) {
  const [items, setItems] = useState(initialItems);
  async function markRead(id: string) {
    const response = await fetch("/api/notifications", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id }),
    });
    if (response.ok)
      setItems((current) =>
        current.map((item) =>
          item.id === id
            ? { ...item, read_at: new Date().toISOString() }
            : item,
        ),
      );
  }
  return (
    <section className="notification-list">
      {items.length === 0 && (
        <p className="empty-state">Yeni bildiriminiz yok.</p>
      )}
      {items.map((item) => (
        <article className={item.read_at ? "read" : ""} key={String(item.id)}>
          <div>
            <strong>{String(item.title)}</strong>
            <p>{String(item.body)}</p>
            <small>
              {new Date(String(item.created_at)).toLocaleString("tr-TR")}
            </small>
          </div>
          {!item.read_at && (
            <button onClick={() => void markRead(String(item.id))}>
              Okundu
            </button>
          )}
        </article>
      ))}
    </section>
  );
}

export function DocumentCenter({ initialItems }: { initialItems: Item[] }) {
  const [items, setItems] = useState(initialItems);
  const [message, setMessage] = useState("");
  async function upload(formData: FormData) {
    setMessage("Dosya doğrulanıyor ve karantinaya yükleniyor…");
    const response = await fetch("/api/documents", {
      method: "POST",
      body: formData,
    });
    const result = await response.json();
    if (response.ok) {
      setItems((current) => [result.data, ...current]);
      setMessage(result.message);
    } else setMessage(result.error ?? "Dosya yüklenemedi.");
  }
  return (
    <div className="operations-grid">
      <form action={upload} className="operation-form">
        <h2>Belge yükle</h2>
        <p>PDF, JPEG, PNG veya DOCX · en fazla 20 MB</p>
        <input
          name="file"
          type="file"
          required
          accept=".pdf,.jpg,.jpeg,.png,.docx"
        />
        <button className="primary">Karantinaya yükle</button>
        {message && <p className="form-message">{message}</p>}
      </form>
      <section className="operation-list">
        {items.map((item) => (
          <article key={String(item.id)}>
            <div>
              <strong>{String(item.file_name)}</strong>
              <small>
                {Number(item.size_bytes ?? 0).toLocaleString("tr-TR")} bayt
              </small>
            </div>
            <span>{String(item.scan_status)}</span>
          </article>
        ))}
      </section>
    </div>
  );
}

export function FormCenter({
  workspaceId,
  initialTemplates,
  initialSubmissions,
}: {
  workspaceId: string;
  initialTemplates: Item[];
  initialSubmissions: Item[];
}) {
  const [templates, setTemplates] = useState(initialTemplates);
  const [submissions, setSubmissions] = useState(initialSubmissions);
  const [message, setMessage] = useState("");
  async function createTemplate(formData: FormData) {
    const response = await fetch("/api/forms", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        kind: "template",
        data: {
          workspaceId,
          name: formData.get("name"),
          description: formData.get("description") || null,
          fields: [
            {
              key: "ziyaret_notu",
              label: formData.get("fieldLabel") || "Ziyaret notu",
              type: "textarea",
              required: true,
            },
          ],
        },
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setTemplates((current) => [...current, result.data]);
      setMessage("Form şablonu oluşturuldu.");
    } else setMessage(result.error ?? "Şablon oluşturulamadı.");
  }
  async function submit(formData: FormData) {
    const templateId = String(formData.get("templateId"));
    const response = await fetch("/api/forms", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        kind: "submission",
        data: { templateId, data: { ziyaret_notu: formData.get("value") } },
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setSubmissions((current) => [result.data, ...current]);
      setMessage("Form yanıtı kaydedildi.");
    } else setMessage(result.error ?? "Yanıt kaydedilemedi.");
  }
  return (
    <div className="operations-grid">
      <div>
        <form action={createTemplate} className="operation-form">
          <h2>Form şablonu</h2>
          <label>
            Form adı
            <input name="name" required />
          </label>
          <label>
            Açıklama
            <input name="description" />
          </label>
          <label>
            İlk alan etiketi
            <input name="fieldLabel" defaultValue="Ziyaret notu" required />
          </label>
          <button className="primary">Şablon oluştur</button>
        </form>
        <form action={submit} className="operation-form structure-team-form">
          <h2>Form doldur</h2>
          <label>
            Şablon
            <select name="templateId">
              {templates.map((item) => (
                <option key={String(item.id)} value={String(item.id)}>
                  {String(item.name)}
                </option>
              ))}
            </select>
          </label>
          <label>
            Yanıt
            <textarea name="value" required />
          </label>
          <button className="primary" disabled={!templates.length}>
            Kaydet
          </button>
        </form>
        {message && <p className="form-message">{message}</p>}
      </div>
      <section className="operation-list">
        <h2>Şablonlar ve yanıtlar</h2>
        {templates.map((item) => (
          <article key={String(item.id)}>
            <div>
              <strong>{String(item.name)}</strong>
              <small>
                v{String(item.version ?? 1)} ·{" "}
                {Array.isArray(item.fields) ? item.fields.length : 0} alan
              </small>
            </div>
          </article>
        ))}
        <p>{submissions.length} kayıtlı yanıt</p>
      </section>
    </div>
  );
}
