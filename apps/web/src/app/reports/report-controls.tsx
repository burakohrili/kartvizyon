"use client";

import { useState } from "react";
import type { ReportFilters } from "@kartvizyon/contracts";
import type { AppLocale } from "@/lib/i18n/locale";
import { formatDateTime } from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";

type Share = {
  id: string;
  title: string;
  expires_at: string;
  revoked_at: string | null;
};

function reportQuery(filters: ReportFilters) {
  const params = new URLSearchParams();
  Object.entries(filters).forEach(([key, value]) => {
    if (value) params.set(key, value);
  });
  return params.toString();
}

export function ReportControls({
  filters,
  workspaceId,
  authenticated,
  initialShares,
  locale,
}: {
  filters: ReportFilters;
  workspaceId: string | null;
  authenticated: boolean;
  initialShares: Share[];
  locale: AppLocale;
}) {
  const m = getMessages(locale).reports;
  const [shares, setShares] = useState(initialShares);
  const [shareUrl, setShareUrl] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  const query = reportQuery(filters);

  async function createShare() {
    if (!workspaceId || !authenticated) {
      setMessage(m.signInRequired);
      return;
    }
    setBusy(true);
    setMessage("");
    try {
      const response = await fetch("/api/reports/shares", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          workspaceId,
          title: m.shareTitle,
          filters,
          validForHours: 168,
        }),
      });
      const result = (await response.json()) as {
        id?: string;
        url?: string;
      };
      if (!response.ok || !result.id || !result.url) {
        setMessage(m.linkCreateFailed);
        return;
      }
      setShareUrl(result.url);
      setShares((current) => [
        {
          id: result.id!,
          title: m.shareTitle,
          expires_at: new Date(Date.now() + 7 * 86400000).toISOString(),
          revoked_at: null,
        },
        ...current,
      ]);
      setMessage(m.linkCreated);
      try {
        await navigator.clipboard.writeText(result.url);
        setMessage(m.linkCreatedCopied);
      } catch {
        setMessage(m.copyFailed);
      }
    } catch {
      setMessage(m.operationFailed);
    } finally {
      setBusy(false);
    }
  }

  async function revokeShare(id: string) {
    setBusy(true);
    try {
      const response = await fetch("/api/reports/shares", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ shareId: id }),
      });
      if (response.ok) {
        setShares((current) =>
          current.map((share) =>
            share.id === id
              ? { ...share, revoked_at: new Date().toISOString() }
              : share,
          ),
        );
        setMessage(m.shareRevoked);
      } else {
        setMessage(m.revokeFailed);
      }
    } catch {
      setMessage(m.revokeFailed);
    } finally {
      setBusy(false);
    }
  }

  async function copyLink() {
    try {
      await navigator.clipboard.writeText(shareUrl);
      setMessage(m.linkCopied);
    } catch {
      setMessage(m.copyFailed);
    }
  }

  return (
    <section className="report-actions" aria-label={m.actions}>
      <div className="report-action-buttons">
        <a
          className="secondary-action"
          href={`/api/reports/export/pdf?${query}`}
        >
          {m.downloadPdf}
        </a>
        <a
          className="secondary-action"
          href={`/api/reports/export/xlsx?${query}`}
        >
          {m.downloadExcel}
        </a>
        <button
          className="primary"
          type="button"
          onClick={createShare}
          disabled={busy}
        >
          {busy ? m.preparing : m.secureLink}
        </button>
      </div>
      {message && (
        <p className="form-message" role="status">
          {message}
        </p>
      )}
      {shareUrl && (
        <div className="share-url">
          <input aria-label={m.linkLabel} readOnly value={shareUrl} />
          <button type="button" onClick={() => void copyLink()}>
            {m.copy}
          </button>
        </div>
      )}
      {shares.length > 0 && (
        <div className="report-share-history">
          <h3>{m.shareHistory}</h3>
          {shares.map((share) => (
            <article key={share.id}>
              <div>
                <strong>{share.title}</strong>
                <small>
                  {share.revoked_at
                    ? m.revoked
                    : `${m.expiresAt}: ${formatDateTime(share.expires_at, locale)}`}
                </small>
              </div>
              {!share.revoked_at && (
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void revokeShare(share.id)}
                >
                  {m.revoke}
                </button>
              )}
            </article>
          ))}
        </div>
      )}
    </section>
  );
}
