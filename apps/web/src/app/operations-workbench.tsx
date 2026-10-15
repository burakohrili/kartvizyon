"use client";

import { useState } from "react";
import type { AppLocale } from "@/lib/i18n/locale";
import { formatCurrency, formatDate, formatDateTime } from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";

type Option = { id: string; name: string };

export function OpportunityWorkbench({
  workspaceId,
  initialItems,
  companies,
  locale,
}: {
  workspaceId: string;
  initialItems: Array<Record<string, unknown>>;
  companies: Option[];
  locale: AppLocale;
}) {
  const m = getMessages(locale).operations;
  const [items, setItems] = useState(initialItems);
  const [message, setMessage] = useState("");

  async function create(formData: FormData) {
    const response = await fetch("/api/opportunities", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        workspaceId,
        companyId: formData.get("companyId"),
        title: formData.get("title"),
        stage: "lead",
        estimatedValue: Number(formData.get("estimatedValue")),
        probability: 10,
        currency: "TRY",
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setItems((current) => [result.data, ...current]);
      setMessage(m.opportunityCreated);
    } else setMessage(m.opportunityCreateFailed);
  }

  async function changeStage(id: string, stage: string) {
    const response = await fetch("/api/opportunities", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id, stage }),
    });
    if (response.ok) {
      setItems((current) =>
        current.map((item) => (item.id === id ? { ...item, stage } : item)),
      );
    }
  }

  return (
    <div className="operations-grid">
      <form action={create} className="operation-form">
        <h2>{m.newOpportunity}</h2>
        <label>
          {m.company}
          <select name="companyId" required>
            {companies.map((company) => (
              <option key={company.id} value={company.id}>
                {company.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          {m.title}
          <input name="title" required minLength={2} />
        </label>
        <label>
          {m.estimatedValue}
          <input name="estimatedValue" type="number" min="0" defaultValue="0" />
        </label>
        <button className="primary" type="submit" disabled={!companies.length}>
          {m.create}
        </button>
        {message && (
          <p className="form-message" role="status">
            {message}
          </p>
        )}
      </form>
      <section className="operation-list opportunity-board">
        {items.map((item) => {
          const company = item.company as { name?: string } | null;
          return (
            <article key={String(item.id)}>
              <div>
                <strong>{String(item.title)}</strong>
                <small>{company?.name ?? m.companyFallback}</small>
              </div>
              <span>
                {formatCurrency(
                  Number(item.estimated_value ?? 0),
                  String(item.currency ?? "TRY"),
                  locale,
                )}
              </span>
              <select
                aria-label={m.stageLabel}
                value={String(item.stage)}
                onChange={(event) =>
                  void changeStage(String(item.id), event.target.value)
                }
              >
                <option value="lead">{m.stageLead}</option>
                <option value="qualified">{m.stageQualified}</option>
                <option value="proposal">{m.stageProposal}</option>
                <option value="negotiation">{m.stageNegotiation}</option>
                <option value="won">{m.stageWon}</option>
                <option value="lost">{m.stageLost}</option>
              </select>
            </article>
          );
        })}
      </section>
    </div>
  );
}

export function ProductWorkbench({
  workspaceId,
  initialItems,
  locale,
}: {
  workspaceId: string;
  initialItems: Array<Record<string, unknown>>;
  locale: AppLocale;
}) {
  const m = getMessages(locale).operations;
  const [items, setItems] = useState(initialItems);
  const [message, setMessage] = useState("");
  async function create(formData: FormData) {
    const response = await fetch("/api/products", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        workspaceId,
        sku: formData.get("sku"),
        name: formData.get("name"),
        unit: formData.get("unit"),
        taxRate: Number(formData.get("taxRate")),
        listPrice: Number(formData.get("listPrice")),
        currency: "TRY",
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setItems((current) => [...current, result.data]);
      setMessage(m.productAdded);
    } else setMessage(m.productAddFailed);
  }
  return (
    <div className="operations-grid">
      <form action={create} className="operation-form">
        <h2>{m.newProduct}</h2>
        <label>
          {m.sku}
          <input name="sku" required />
        </label>
        <label>
          {m.productName}
          <input name="name" required />
        </label>
        <label>
          {m.unit}
          <input
            name="unit"
            defaultValue={locale === "en" ? "piece" : "adet"}
            required
          />
        </label>
        <label>
          {m.taxRate}
          <input
            name="taxRate"
            type="number"
            defaultValue="20"
            min="0"
            max="100"
          />
        </label>
        <label>
          {m.listPrice}
          <input name="listPrice" type="number" min="0" step="0.01" required />
        </label>
        <button className="primary" type="submit">
          {m.add}
        </button>
        {message && (
          <p className="form-message" role="status">
            {message}
          </p>
        )}
      </form>
      <section className="operation-list">
        {items.map((item) => (
          <article key={String(item.id)}>
            <div>
              <strong>{String(item.name)}</strong>
              <small>
                {String(item.sku)} · {String(item.unit)}
              </small>
            </div>
            <span>
              {formatCurrency(
                Number(item.list_price),
                String(item.currency ?? "TRY"),
                locale,
              )}
            </span>
          </article>
        ))}
      </section>
    </div>
  );
}

/**
 * Fiyat listesi PDF'i yükler ve mevcut listeleri gösterir.
 *
 * Ayrı bir hat kurulmaz: belge karantinası, imza doğrulaması ve ClamAV
 * taraması `documents` üzerinde zaten çalışıyor. Fiyat listesi bunların
 * hepsine ihtiyaç duyar (ADR-0007).
 */
export function PriceListWorkbench({
  initialItems,
  locale,
}: {
  initialItems: Array<Record<string, unknown>>;
  locale: AppLocale;
}) {
  const m = getMessages(locale).operations;
  const [items, setItems] = useState(initialItems);
  const [message, setMessage] = useState("");
  async function upload(formData: FormData) {
    formData.set("purpose", "price_list");
    setMessage(m.priceListValidating);
    const response = await fetch("/api/documents", {
      method: "POST",
      body: formData,
    });
    const result = await response.json();
    if (response.ok) {
      setItems((current) => [result.data, ...current]);
      setMessage(m.priceListUploaded);
    } else setMessage(m.priceListUploadFailed);
  }
  return (
    <div className="operations-grid">
      <form action={upload} className="operation-form">
        <h2>{m.uploadPriceList}</h2>
        <p>{m.priceListRequirements}</p>
        <input name="file" type="file" required accept=".pdf" />
        <button className="primary">{m.quarantineUpload}</button>
        {message && (
          <p className="form-message" role="status">
            {message}
          </p>
        )}
      </form>
      <section className="operation-list">
        {items.map((item) => (
          <article key={String(item.id)}>
            <div>
              <strong>{String(item.file_name)}</strong>
              <small>{formatDate(String(item.created_at), locale)}</small>
            </div>
            {item.scan_status === "clean" ? (
              <a href={`/api/documents/${String(item.id)}/download`}>
                {m.download}
              </a>
            ) : (
              <span>
                {item.scan_status === "pending"
                  ? m.scanPending
                  : item.scan_status === "infected"
                    ? m.scanInfected
                    : item.scan_status === "error"
                      ? m.scanError
                      : m.scanUnknown}
              </span>
            )}
          </article>
        ))}
      </section>
    </div>
  );
}

export function OrderWorkbench({
  workspaceId,
  initialItems,
  companies,
  products,
  locale,
}: {
  workspaceId: string;
  initialItems: Array<Record<string, unknown>>;
  companies: Option[];
  products: Array<Option & { listPrice: number }>;
  locale: AppLocale;
}) {
  const m = getMessages(locale).operations;
  const [items, setItems] = useState(initialItems);
  const [message, setMessage] = useState("");
  async function create(formData: FormData) {
    const product = products.find(
      (candidate) => candidate.id === formData.get("productId"),
    );
    if (!product) return;
    const response = await fetch("/api/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        workspaceId,
        companyId: formData.get("companyId"),
        currency: "TRY",
        items: [
          {
            productId: product.id,
            quantity: Number(formData.get("quantity")),
            unitPrice: product.listPrice,
            discountPercent: Number(formData.get("discountPercent")),
          },
        ],
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setItems((current) => [result.data, ...current]);
      setMessage(m.orderCreated);
    } else setMessage(m.orderCreateFailed);
  }
  async function transition(id: string, status: string) {
    const response = await fetch(`/api/orders/${id}/transition`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        status,
        rejectionReason: status === "rejected" ? m.rejectedByManager : null,
      }),
    });
    if (response.ok)
      setItems((current) =>
        current.map((item) => (item.id === id ? { ...item, status } : item)),
      );
  }
  return (
    <div className="operations-grid">
      <form action={create} className="operation-form">
        <h2>{m.newOrderDraft}</h2>
        <label>
          {m.company}
          <select name="companyId" required>
            {companies.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          {m.product}
          <select name="productId" required>
            {products.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          {m.quantity}
          <input
            name="quantity"
            type="number"
            min="0.001"
            step="0.001"
            defaultValue="1"
          />
        </label>
        <label>
          {m.discount}
          <input
            name="discountPercent"
            type="number"
            min="0"
            max="100"
            defaultValue="0"
          />
        </label>
        <button
          className="primary"
          type="submit"
          disabled={!companies.length || !products.length}
        >
          {m.createDraft}
        </button>
        {message && (
          <p className="form-message" role="status">
            {message}
          </p>
        )}
      </form>
      <section className="operation-list">
        {items.map((item) => {
          const company = item.company as { name?: string } | null;
          return (
            <article key={String(item.id)}>
              <div>
                <strong>{company?.name ?? m.companyFallback}</strong>
                <small>
                  {item.status === "draft"
                    ? m.statusDraft
                    : item.status === "pending_approval"
                      ? m.statusPending
                      : item.status === "approved"
                        ? m.statusApproved
                        : item.status === "rejected"
                          ? m.statusRejected
                          : m.statusDraft}
                </small>
              </div>
              <span>
                {formatCurrency(
                  Number(item.grand_total ?? 0),
                  String(item.currency ?? "TRY"),
                  locale,
                )}
              </span>
              <div className="inline-actions">
                {item.status === "draft" && (
                  <button
                    onClick={() =>
                      void transition(String(item.id), "pending_approval")
                    }
                  >
                    {m.submitForApproval}
                  </button>
                )}
                {item.status === "pending_approval" && (
                  <>
                    <button
                      onClick={() =>
                        void transition(String(item.id), "approved")
                      }
                    >
                      {m.approve}
                    </button>
                    <button
                      onClick={() =>
                        void transition(String(item.id), "rejected")
                      }
                    >
                      {m.reject}
                    </button>
                  </>
                )}
              </div>
            </article>
          );
        })}
      </section>
    </div>
  );
}

export function CalendarWorkbench({
  workspaceId,
  userId,
  companies,
  initialVisits,
  locale,
}: {
  workspaceId: string;
  userId: string;
  companies: Option[];
  initialVisits: Array<Record<string, unknown>>;
  locale: AppLocale;
}) {
  const m = getMessages(locale).calendar;
  const [visits, setVisits] = useState(initialVisits);
  const [message, setMessage] = useState("");
  async function create(formData: FormData) {
    const start = new Date(String(formData.get("start")));
    const end = new Date(start.getTime() + 60 * 60 * 1000);
    const response = await fetch("/api/calendar", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        workspaceId,
        companyId: formData.get("companyId"),
        representativeId: userId,
        purpose: formData.get("purpose"),
        plannedStartAt: start.toISOString(),
        plannedEndAt: end.toISOString(),
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setVisits((current) => [...current, result.data]);
      setMessage(m.planned);
    } else setMessage(m.failed);
  }
  return (
    <div className="operations-grid">
      <form action={create} className="operation-form">
        <h2>{m.planVisit}</h2>
        <label>
          {m.company}
          <select name="companyId">
            {companies.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          {m.purpose}
          <input name="purpose" required />
        </label>
        <label>
          {m.dateTime}
          <input name="start" type="datetime-local" required />
        </label>
        <button className="primary" disabled={!companies.length}>
          {m.plan}
        </button>
        {message && <p className="form-message">{message}</p>}
      </form>
      <section className="operation-list">
        {visits.map((visit) => {
          const company = visit.company as { name?: string } | null;
          return (
            <article key={String(visit.id)}>
              <div>
                <strong>{company?.name ?? m.noCompany}</strong>
                <small>{String(visit.purpose ?? m.plannedVisit)}</small>
              </div>
              <time>
                {formatDateTime(String(visit.planned_start_at), locale)}
              </time>
            </article>
          );
        })}
      </section>
    </div>
  );
}
