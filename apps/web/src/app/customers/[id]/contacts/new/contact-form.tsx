"use client";

import type { BusinessCardExtraction } from "@kartvizyon/contracts";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { createContact } from "./actions";

const empty = { firstName: "", lastName: "", title: "", phone: "", email: "" };

export function ContactForm({ companyId }: { companyId: string }) {
  const [fields, setFields] = useState(empty);
  const [companyName, setCompanyName] = useState<string | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [processing, setProcessing] = useState(false);
  const [message, setMessage] = useState("");

  useEffect(
    () => () => {
      if (preview) URL.revokeObjectURL(preview);
    },
    [preview],
  );
  function update(name: keyof typeof empty, value: string) {
    setFields((current) => ({ ...current, [name]: value }));
  }
  async function scanCard(file: File) {
    if (preview) URL.revokeObjectURL(preview);
    setPreview(URL.createObjectURL(file));
    setProcessing(true);
    setMessage("");
    const form = new FormData();
    form.set("image", file);
    try {
      const response = await fetch("/api/contacts/ocr", {
        method: "POST",
        body: form,
      });
      const result = (await response.json()) as {
        data?: BusinessCardExtraction;
        error?: string;
      };
      if (!response.ok || !result.data)
        throw new Error(result.error ?? "Kartvizit okunamadı.");
      const data = result.data;
      setFields({
        firstName: data.firstName ?? "",
        lastName: data.lastName ?? "",
        title: data.title ?? "",
        phone: data.phone ?? "",
        email: data.email ?? "",
      });
      setCompanyName(data.companyName);
      setMessage(
        `AI taslağı hazır · güven %${Math.round(data.confidence * 100)} · kaydetmeden önce kontrol edin`,
      );
    } catch (error) {
      setMessage(
        error instanceof Error ? error.message : "Kartvizit okunamadı.",
      );
    } finally {
      setProcessing(false);
    }
  }

  return (
    <>
      <section className="ocr-panel">
        <div className="ocr-copy">
          <span className="eyebrow">KARTVİZİTİ TARA</span>
          <strong>Fotoğraftan formu doldur</strong>
          <small>JPEG, PNG veya WebP · en fazla 10 MB</small>
          <label className="ocr-button">
            {processing ? "AI okuyor…" : "Kartvizit seç"}
            <input
              type="file"
              accept="image/jpeg,image/png,image/webp"
              disabled={processing}
              onChange={(event) => {
                const file = event.target.files?.[0];
                if (file) void scanCard(file);
              }}
            />
          </label>
        </div>
        {preview && (
          <Image
            src={preview}
            alt="Seçilen kartvizit"
            width={180}
            height={110}
            unoptimized
            className="ocr-preview"
          />
        )}
      </section>
      {message && (
        <p className="ocr-message" role="status">
          {message}
        </p>
      )}
      {companyName && (
        <p className="ocr-company">
          Kartta görünen firma: <strong>{companyName}</strong>
        </p>
      )}
      <form action={createContact} className="entity-form">
        <input type="hidden" name="companyId" value={companyId} />
        <div className="form-row">
          <label>
            Ad *
            <input
              name="firstName"
              required
              value={fields.firstName}
              onChange={(e) => update("firstName", e.target.value)}
            />
          </label>
          <label>
            Soyad
            <input
              name="lastName"
              value={fields.lastName}
              onChange={(e) => update("lastName", e.target.value)}
            />
          </label>
        </div>
        <label>
          Pozisyon
          <input
            name="title"
            value={fields.title}
            onChange={(e) => update("title", e.target.value)}
          />
        </label>
        <div className="form-row">
          <label>
            Telefon
            <input
              name="phone"
              type="tel"
              value={fields.phone}
              onChange={(e) => update("phone", e.target.value)}
            />
          </label>
          <label>
            E-posta
            <input
              name="email"
              type="email"
              value={fields.email}
              onChange={(e) => update("email", e.target.value)}
            />
          </label>
        </div>
        <div className="form-actions">
          <Link href={`/customers/${companyId}`}>Vazgeç</Link>
          <button className="primary" type="submit">
            Kontrol ettim, kişiyi kaydet
          </button>
        </div>
      </form>
    </>
  );
}
