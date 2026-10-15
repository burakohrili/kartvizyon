"use client";

import { useState } from "react";
import type { AppLocale } from "@/lib/i18n/locale";
import { formatDateTime } from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";

type Item = Record<string, unknown>;

export function ActivityFeed({
  initialVisits,
  initialComments,
  locale,
}: {
  initialVisits: Item[];
  initialComments: Item[];
  locale: AppLocale;
}) {
  const m = getMessages(locale).activity;
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
      setMessage(m.commentAdded);
    } else setMessage(m.commentFailed);
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
                <strong>{company?.name ?? m.company}</strong>
                <small>{representative?.full_name ?? m.representative}</small>
              </div>
              <time>{formatDateTime(String(visit.approved_at), locale)}</time>
            </header>
            <p>{summary?.summary ?? m.approvedVisit}</p>
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
                aria-label={m.managerComment}
                placeholder={m.commentPlaceholder}
                required
                maxLength={2000}
              />
              <button>{m.addComment}</button>
            </form>
          </article>
        );
      })}
    </section>
  );
}

export function NotificationCenter({
  initialItems,
  locale,
}: {
  initialItems: Item[];
  locale: AppLocale;
}) {
  const m = getMessages(locale).notifications;
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
      {items.length === 0 && <p className="empty-state">{m.empty}</p>}
      {items.map((item) => (
        <article className={item.read_at ? "read" : ""} key={String(item.id)}>
          <div>
            <strong>{String(item.title)}</strong>
            <p>{String(item.body)}</p>
            <small>{formatDateTime(String(item.created_at), locale)}</small>
          </div>
          {!item.read_at && (
            <button onClick={() => void markRead(String(item.id))}>
              {m.markRead}
            </button>
          )}
        </article>
      ))}
    </section>
  );
}

export function DocumentCenter({
  initialItems,
  locale,
}: {
  initialItems: Item[];
  locale: AppLocale;
}) {
  const m = getMessages(locale).operations;
  const [items, setItems] = useState(initialItems);
  const [message, setMessage] = useState("");
  async function upload(formData: FormData) {
    setMessage(m.validatingDocument);
    const response = await fetch("/api/documents", {
      method: "POST",
      body: formData,
    });
    const result = await response.json();
    if (response.ok) {
      setItems((current) => [result.data, ...current]);
      setMessage(m.documentUploaded);
    } else setMessage(m.documentUploadFailed);
  }
  return (
    <div className="operations-grid">
      <form action={upload} className="operation-form">
        <h2>{m.uploadDocument}</h2>
        <p>{m.documentRequirements}</p>
        <input
          name="file"
          type="file"
          required
          accept=".pdf,.jpg,.jpeg,.png,.docx"
        />
        <button className="primary">{m.quarantine}</button>
        {message && <p className="form-message">{message}</p>}
      </form>
      <section className="operation-list">
        {items.map((item) => (
          <article key={String(item.id)}>
            <div>
              <strong>{String(item.file_name)}</strong>
              <small>
                {Number(item.size_bytes ?? 0).toLocaleString(
                  locale === "en" ? "en-US" : "tr-TR",
                )}{" "}
                {m.bytes}
              </small>
            </div>
            <span>
              {item.scan_status === "pending"
                ? m.scanPending
                : item.scan_status === "clean"
                  ? m.scanClean
                  : item.scan_status === "infected"
                    ? m.scanInfected
                    : item.scan_status === "error"
                      ? m.scanError
                      : m.scanUnknown}
            </span>
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
  locale,
}: {
  workspaceId: string;
  initialTemplates: Item[];
  initialSubmissions: Item[];
  locale: AppLocale;
}) {
  const m = getMessages(locale).operations;
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
              label: formData.get("fieldLabel") || m.visitNote,
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
      setMessage(m.templateCreated);
    } else setMessage(m.templateCreateFailed);
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
      setMessage(m.responseSaved);
    } else setMessage(m.responseSaveFailed);
  }
  return (
    <div className="operations-grid">
      <div>
        <form action={createTemplate} className="operation-form">
          <h2>{m.formTemplate}</h2>
          <label>
            {m.formName}
            <input name="name" required />
          </label>
          <label>
            {m.description}
            <input name="description" />
          </label>
          <label>
            {m.firstFieldLabel}
            <input name="fieldLabel" defaultValue={m.visitNote} required />
          </label>
          <button className="primary">{m.createTemplate}</button>
        </form>
        <form action={submit} className="operation-form structure-team-form">
          <h2>{m.fillForm}</h2>
          <label>
            {m.template}
            <select name="templateId">
              {templates.map((item) => (
                <option key={String(item.id)} value={String(item.id)}>
                  {String(item.name)}
                </option>
              ))}
            </select>
          </label>
          <label>
            {m.response}
            <textarea name="value" required />
          </label>
          <button className="primary" disabled={!templates.length}>
            {m.save}
          </button>
        </form>
        {message && <p className="form-message">{message}</p>}
      </div>
      <section className="operation-list">
        <h2>{m.templatesAndResponses}</h2>
        {templates.map((item) => (
          <article key={String(item.id)}>
            <div>
              <strong>{String(item.name)}</strong>
              <small>
                v{String(item.version ?? 1)} ·{" "}
                {Array.isArray(item.fields) ? item.fields.length : 0} {m.fields}
              </small>
            </div>
          </article>
        ))}
        <p>
          {submissions.length} {m.savedResponses}
        </p>
      </section>
    </div>
  );
}
