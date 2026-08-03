"use client";

import { useState } from "react";
import type { ReportFilters } from "@kartvizyon/contracts";

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
}: {
  filters: ReportFilters;
  workspaceId: string | null;
  authenticated: boolean;
  initialShares: Share[];
}) {
  const [shares, setShares] = useState(initialShares);
  const [shareUrl, setShareUrl] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  const query = reportQuery(filters);

  async function createShare() {
    if (!workspaceId || !authenticated) {
      setMessage("Güvenli bağlantı için Supabase oturumu gereklidir.");
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
          title: "Satış aktivite raporu",
          filters,
          validForHours: 168,
        }),
      });
      const result = (await response.json()) as {
        id?: string;
        url?: string;
        error?: string;
      };
      if (!response.ok || !result.id || !result.url) {
        throw new Error(result.error ?? "Bağlantı oluşturulamadı.");
      }
      setShareUrl(result.url);
      setShares((current) => [
        {
          id: result.id!,
          title: "Satış aktivite raporu",
          expires_at: new Date(Date.now() + 7 * 86400000).toISOString(),
          revoked_at: null,
        },
        ...current,
      ]);
      await navigator.clipboard.writeText(result.url);
      setMessage("Güvenli bağlantı oluşturuldu ve panoya kopyalandı.");
    } catch (error) {
      setMessage(
        error instanceof Error ? error.message : "İşlem tamamlanamadı.",
      );
    } finally {
      setBusy(false);
    }
  }

  async function revokeShare(id: string) {
    setBusy(true);
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
      setMessage("Paylaşım bağlantısı iptal edildi.");
    } else {
      setMessage("Bağlantı iptal edilemedi.");
    }
    setBusy(false);
  }

  return (
    <section className="report-actions" aria-label="Rapor işlemleri">
      <div className="report-action-buttons">
        <a
          className="secondary-action"
          href={`/api/reports/export/pdf?${query}`}
        >
          PDF indir
        </a>
        <a
          className="secondary-action"
          href={`/api/reports/export/xlsx?${query}`}
        >
          Excel indir
        </a>
        <button
          className="primary"
          type="button"
          onClick={createShare}
          disabled={busy}
        >
          {busy ? "Hazırlanıyor…" : "7 günlük güvenli bağlantı"}
        </button>
      </div>
      {message && (
        <p className="form-message" role="status">
          {message}
        </p>
      )}
      {shareUrl && (
        <div className="share-url">
          <input
            aria-label="Güvenli rapor bağlantısı"
            readOnly
            value={shareUrl}
          />
          <button
            type="button"
            onClick={() => void navigator.clipboard.writeText(shareUrl)}
          >
            Kopyala
          </button>
        </div>
      )}
      {shares.length > 0 && (
        <div className="report-share-history">
          <h3>Paylaşım geçmişi</h3>
          {shares.map((share) => (
            <article key={share.id}>
              <div>
                <strong>{share.title}</strong>
                <small>
                  {share.revoked_at
                    ? "İptal edildi"
                    : `${new Date(share.expires_at).toLocaleString("tr-TR")} tarihine kadar`}
                </small>
              </div>
              {!share.revoked_at && (
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => void revokeShare(share.id)}
                >
                  İptal et
                </button>
              )}
            </article>
          ))}
        </div>
      )}
    </section>
  );
}
