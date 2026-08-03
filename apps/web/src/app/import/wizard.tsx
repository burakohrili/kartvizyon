"use client";

import { useState, type FormEvent } from "react";

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
const fields = [
  { key: "name", label: "Firma adı *" },
  { key: "phone", label: "Telefon" },
  { key: "email", label: "E-posta" },
  { key: "website", label: "Web sitesi" },
  { key: "address", label: "Adres" },
];

export function ImportWizard({
  workspaceId,
  organizationId,
}: {
  workspaceId: string;
  organizationId: string | null;
}) {
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
    const response = await fetch("/api/imports", {
      method: "POST",
      body: form,
    });
    const payload = await response.json();
    if (!response.ok) setError(payload.error ?? "İşlem tamamlanamadı.");
    else if (action === "preview") {
      setPreview(payload.data);
      setMapping(payload.data.suggestedMapping);
      setResult(null);
    } else setResult(payload.data);
    setBusy(false);
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
          <strong>{file?.name ?? "CSV veya XLSX dosyanızı seçin"}</strong>
          <span>En fazla 10 MB ve 10.000 veri satırı</span>
        </label>
        <button className="primary" disabled={!file || busy}>
          {busy ? "İşleniyor…" : "Ön izleme oluştur"}
        </button>
      </form>
      {error && <div className="form-message error-message">{error}</div>}
      {preview && (
        <>
          <div className="mapping-grid">
            <div>
              <span className="eyebrow">KOLON EŞLEME</span>
              <h2>{preview.totalRows} satır bulundu</h2>
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
                  <option value="">Eşleme yok</option>
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
            <small>
              İlk 8 satır gösteriliyor. Formül benzeri hücreler güvenli metne
              dönüştürülür.
            </small>
            <button
              className="primary"
              disabled={!mapping.name || busy}
              onClick={() => void request("execute")}
            >
              {busy ? "İçe aktarılıyor…" : "İçe aktarmayı başlat"}
            </button>
          </div>
        </>
      )}
      {result && (
        <div className="import-result">
          <strong>
            {result.simulated
              ? "Demo içe aktarma tamamlandı"
              : "İçe aktarma tamamlandı"}
          </strong>
          <p>
            {result.importedRows ?? result.importableRows ?? 0} satır hazır ·{" "}
            {result.skippedRows} satır atlandı
          </p>
          {result.simulated && (
            <small>
              Supabase bağlandığında aynı doğrulanmış satırlar veritabanına
              yazılır.
            </small>
          )}
        </div>
      )}
    </section>
  );
}
