"use client";

import { useState } from "react";

type Option = { id: string; name: string };

export function OpportunityWorkbench({
  workspaceId,
  initialItems,
  companies,
}: {
  workspaceId: string;
  initialItems: Array<Record<string, unknown>>;
  companies: Option[];
}) {
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
      setMessage("Fırsat oluşturuldu.");
    } else setMessage(result.error ?? "Fırsat oluşturulamadı.");
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
        <h2>Yeni fırsat</h2>
        <label>
          Firma
          <select name="companyId" required>
            {companies.map((company) => (
              <option key={company.id} value={company.id}>
                {company.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Başlık
          <input name="title" required minLength={2} />
        </label>
        <label>
          Tahmini değer
          <input name="estimatedValue" type="number" min="0" defaultValue="0" />
        </label>
        <button className="primary" type="submit" disabled={!companies.length}>
          Oluştur
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
                <small>{company?.name ?? "Firma"}</small>
              </div>
              <span>
                {Number(item.estimated_value ?? 0).toLocaleString("tr-TR")}{" "}
                {String(item.currency ?? "TRY")}
              </span>
              <select
                aria-label="Fırsat aşaması"
                value={String(item.stage)}
                onChange={(event) =>
                  void changeStage(String(item.id), event.target.value)
                }
              >
                <option value="lead">Yeni</option>
                <option value="qualified">Nitelikli</option>
                <option value="proposal">Teklif</option>
                <option value="negotiation">Müzakere</option>
                <option value="won">Kazanıldı</option>
                <option value="lost">Kaybedildi</option>
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
}: {
  workspaceId: string;
  initialItems: Array<Record<string, unknown>>;
}) {
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
      setMessage("Ürün eklendi.");
    } else setMessage(result.error ?? "Ürün eklenemedi.");
  }
  return (
    <div className="operations-grid">
      <form action={create} className="operation-form">
        <h2>Yeni ürün</h2>
        <label>
          SKU
          <input name="sku" required />
        </label>
        <label>
          Ürün adı
          <input name="name" required />
        </label>
        <label>
          Birim
          <input name="unit" defaultValue="adet" required />
        </label>
        <label>
          KDV %
          <input
            name="taxRate"
            type="number"
            defaultValue="20"
            min="0"
            max="100"
          />
        </label>
        <label>
          Liste fiyatı
          <input name="listPrice" type="number" min="0" step="0.01" required />
        </label>
        <button className="primary" type="submit">
          Ekle
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
              {Number(item.list_price).toLocaleString("tr-TR")}{" "}
              {String(item.currency)}
            </span>
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
}: {
  workspaceId: string;
  initialItems: Array<Record<string, unknown>>;
  companies: Option[];
  products: Array<Option & { listPrice: number }>;
}) {
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
      setMessage("Sipariş taslağı oluşturuldu.");
    } else setMessage(result.error ?? "Taslak oluşturulamadı.");
  }
  async function transition(id: string, status: string) {
    const response = await fetch(`/api/orders/${id}/transition`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        status,
        rejectionReason:
          status === "rejected" ? "Yönetici tarafından reddedildi" : null,
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
        <h2>Yeni sipariş taslağı</h2>
        <label>
          Firma
          <select name="companyId" required>
            {companies.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Ürün
          <select name="productId" required>
            {products.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Miktar
          <input
            name="quantity"
            type="number"
            min="0.001"
            step="0.001"
            defaultValue="1"
          />
        </label>
        <label>
          İskonto %
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
          Taslak oluştur
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
                <strong>{company?.name ?? "Firma"}</strong>
                <small>{String(item.status)}</small>
              </div>
              <span>
                {Number(item.grand_total ?? 0).toLocaleString("tr-TR")}{" "}
                {String(item.currency)}
              </span>
              <div className="inline-actions">
                {item.status === "draft" && (
                  <button
                    onClick={() =>
                      void transition(String(item.id), "pending_approval")
                    }
                  >
                    Onaya gönder
                  </button>
                )}
                {item.status === "pending_approval" && (
                  <>
                    <button
                      onClick={() =>
                        void transition(String(item.id), "approved")
                      }
                    >
                      Onayla
                    </button>
                    <button
                      onClick={() =>
                        void transition(String(item.id), "rejected")
                      }
                    >
                      Reddet
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
}: {
  workspaceId: string;
  userId: string;
  companies: Option[];
  initialVisits: Array<Record<string, unknown>>;
}) {
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
      setMessage("Ziyaret planlandı.");
    } else setMessage(result.error ?? "Ziyaret planlanamadı.");
  }
  return (
    <div className="operations-grid">
      <form action={create} className="operation-form">
        <h2>Ziyaret planla</h2>
        <label>
          Firma
          <select name="companyId">
            {companies.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Amaç
          <input name="purpose" required />
        </label>
        <label>
          Tarih ve saat
          <input name="start" type="datetime-local" required />
        </label>
        <button className="primary" disabled={!companies.length}>
          Planla
        </button>
        {message && <p className="form-message">{message}</p>}
      </form>
      <section className="operation-list">
        {visits.map((visit) => {
          const company = visit.company as { name?: string } | null;
          return (
            <article key={String(visit.id)}>
              <div>
                <strong>{company?.name ?? "Firma"}</strong>
                <small>{String(visit.purpose ?? "Planlı ziyaret")}</small>
              </div>
              <time>
                {new Date(String(visit.planned_start_at)).toLocaleString(
                  "tr-TR",
                )}
              </time>
            </article>
          );
        })}
      </section>
    </div>
  );
}
