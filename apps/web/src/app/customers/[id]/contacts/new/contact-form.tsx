"use client";

import type { BusinessCardExtraction } from "@kartvizyon/contracts";
import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { createContact } from "./actions";
import { getMessages } from "@/lib/i18n/messages";
import type { AppLocale } from "@/lib/i18n/locale";

const empty = { firstName: "", lastName: "", title: "", phone: "", email: "" };

export function ContactForm({
  companyId,
  locale,
}: {
  companyId: string;
  locale: AppLocale;
}) {
  const messages = getMessages(locale).customerForms;
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
      if (!response.ok || !result.data) throw new Error(messages.scanFailed);
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
        messages.scanReady.replace(
          "{confidence}",
          String(Math.round(data.confidence * 100)),
        ),
      );
    } catch (error) {
      setMessage(error instanceof Error ? error.message : messages.scanFailed);
    } finally {
      setProcessing(false);
    }
  }

  return (
    <>
      <section className="ocr-panel">
        <div className="ocr-copy">
          <span className="eyebrow">{messages.scanEyebrow}</span>
          <strong>{messages.scanTitle}</strong>
          <small>{messages.scanRequirements}</small>
          <label className="ocr-button">
            {processing ? messages.aiReading : messages.chooseCard}
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
            alt={messages.selectedCard}
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
          {messages.cardCompany} <strong>{companyName}</strong>
        </p>
      )}
      <form action={createContact} className="entity-form">
        <input type="hidden" name="companyId" value={companyId} />
        <div className="form-row">
          <label>
            {messages.firstName} *
            <input
              name="firstName"
              required
              value={fields.firstName}
              onChange={(e) => update("firstName", e.target.value)}
            />
          </label>
          <label>
            {messages.lastName}
            <input
              name="lastName"
              value={fields.lastName}
              onChange={(e) => update("lastName", e.target.value)}
            />
          </label>
        </div>
        <label>
          {messages.jobTitle}
          <input
            name="title"
            value={fields.title}
            onChange={(e) => update("title", e.target.value)}
          />
        </label>
        <div className="form-row">
          <label>
            {messages.contactPhone}
            <input
              name="phone"
              type="tel"
              value={fields.phone}
              onChange={(e) => update("phone", e.target.value)}
            />
          </label>
          <label>
            {messages.contactEmail}
            <input
              name="email"
              type="email"
              value={fields.email}
              onChange={(e) => update("email", e.target.value)}
            />
          </label>
        </div>
        <div className="form-actions">
          <Link href={`/customers/${companyId}`}>{messages.cancel}</Link>
          <button className="primary" type="submit">
            {messages.reviewedSave}
          </button>
        </div>
      </form>
    </>
  );
}
