"use client";

import { useState, type FormEvent } from "react";
import { getMessages } from "@/lib/i18n/messages";
import type { AppLocale } from "@/lib/i18n/locale";
import { formatNumber } from "@/lib/i18n/locale";

type Preview = {
  headers: string[];
  previewRows: Record<string, string>[];
  totalRows: number;
  suggestedMapping: Record<string, string | null>;
};
type Result = {
  simulated?: boolean;
  totalRows: number;
  importableRows?: number;
  importedRows?: number;
  skippedRows: number;
  errors: Array<{ row: number; reason: string }>;
};
export function ImportWizard({
  workspaceId,
  organizationId,
  locale,
}: {
  workspaceId: string;
  organizationId: string | null;
  locale: AppLocale;
}) {
  const messages = getMessages(locale).import;
  const fields = Object.entries(messages.fields).map(([key, label]) => ({
    key,
    label,
  }));
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<Preview | null>(null);
  const [mapping, setMapping] = useState<Record<string, string | null>>({});
  const [result, setResult] = useState<Result | null>(null);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  async function request(action: "preview" | "execute") {
    if (!file) return;
    setBusy(true);
    setError("");
    const form = new FormData();
    form.set("file", file);
    form.set("action", action);
    if (action === "execute") {
      form.set("mapping", JSON.stringify(mapping));
      form.set("workspaceId", workspaceId);
      if (organizationId) form.set("organizationId", organizationId);
    }
    try {
      const response = await fetch("/api/imports", {
        method: "POST",
        body: form,
      });
      const payload = await response.json();
      if (!response.ok) setError(messages.importFailed);
      else if (action === "preview") {
        setPreview(payload.data);
        setMapping(payload.data.suggestedMapping);
        setResult(null);
      } else setResult(payload.data);
    } catch {
      setError(messages.importFailed);
    } finally {
      setBusy(false);
    }
  }

  function submit(event: FormEvent) {
    event.preventDefault();
    void request("preview");
  }
  return (
    <section className="import-card">
      <form onSubmit={submit} className="upload-box">
        <input
          id="import-file"
          type="file"
          accept=".csv,.xlsx"
          onChange={(event) => {
            setFile(event.target.files?.[0] ?? null);
            setPreview(null);
            setResult(null);
          }}
        />
        <label htmlFor="import-file">
          <strong>{file?.name ?? messages.chooseFile}</strong>
          <span>{messages.fileLimit}</span>
        </label>
        <button className="primary" disabled={!file || busy}>
          {busy ? messages.processing : messages.preview}
        </button>
      </form>
      {error && <div className="form-message error-message">{error}</div>}
      {preview && (
        <>
          <div className="mapping-grid">
            <div>
              <span className="eyebrow">{messages.mapping}</span>
              <h2>
                {messages.rowsFound.replace(
                  "{count}",
                  formatNumber(preview.totalRows, locale),
                )}
              </h2>
            </div>
            {fields.map((field) => (
              <label key={field.key}>
                {field.label}
                <select
                  value={mapping[field.key] ?? ""}
                  onChange={(event) =>
                    setMapping((current) => ({
                      ...current,
                      [field.key]: event.target.value || null,
                    }))
                  }
                >
                  <option value="">{messages.noMapping}</option>
                  {preview.headers.map((header) => (
                    <option key={header}>{header}</option>
                  ))}
                </select>
              </label>
            ))}
          </div>
          <div className="preview-table-wrap">
            <table className="customer-table">
              <thead>
                <tr>
                  {preview.headers.map((header) => (
                    <th key={header}>{header}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {preview.previewRows.slice(0, 8).map((row, index) => (
                  <tr key={index}>
                    {preview.headers.map((header) => (
                      <td key={header}>{row[header]}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="import-actions">
            <small>{messages.firstRows}</small>
            <button
              className="primary"
              disabled={!mapping.name || busy}
              onClick={() => void request("execute")}
            >
              {busy ? messages.importing : messages.startImport}
            </button>
          </div>
        </>
      )}
      {result && (
        <div className="import-result">
          <strong>
            {result.simulated ? messages.demoComplete : messages.complete}
          </strong>
          <p>
            {formatNumber(
              result.importedRows ?? result.importableRows ?? 0,
              locale,
            )}{" "}
            {messages.rowsReady} · {formatNumber(result.skippedRows, locale)}{" "}
            {messages.rowsSkipped}
          </p>
          {result.simulated && <small>{messages.demoNote}</small>}
        </div>
      )}
    </section>
  );
}
