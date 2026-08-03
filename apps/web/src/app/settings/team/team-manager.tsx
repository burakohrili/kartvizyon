"use client";

import { useState, type FormEvent } from "react";

const members = [
  {
    name: "Burak Köse",
    email: "burak@vizyon.com",
    role: "Organizasyon sahibi",
    status: "Aktif",
  },
  {
    name: "Ece Yılmaz",
    email: "ece@vizyon.com",
    role: "Saha satış",
    status: "Aktif",
  },
  {
    name: "Can Demir",
    email: "can@vizyon.com",
    role: "Takım lideri",
    status: "Aktif",
  },
];

export function TeamManager({ organizationId }: { organizationId: string }) {
  const [inviteUrl, setInviteUrl] = useState("");
  const [message, setMessage] = useState("");
  async function invite(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setMessage("Davet hazırlanıyor…");
    const expiresAt = new Date(Date.now() + 7 * 86_400_000).toISOString();
    const response = await fetch("/api/invitations", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        organizationId,
        email: form.get("email"),
        role: form.get("role"),
        expiresAt,
      }),
    });
    if (response.status === 503) {
      const demoToken = "a".repeat(64);
      setInviteUrl(`${window.location.origin}/invite/${demoToken}`);
      setMessage(
        "Demo davet bağlantısı üretildi. Supabase bağlandığında hash'i veritabanında saklanır.",
      );
      return;
    }
    const payload = await response.json();
    if (!response.ok) {
      setMessage(payload.error ?? "Davet oluşturulamadı.");
      return;
    }
    setInviteUrl(payload.data.inviteUrl);
    setMessage("Davet bağlantısı yalnızca bu ekranda bir kez gösterilir.");
  }
  return (
    <div className="team-layout">
      <section className="team-panel">
        <div className="detail-heading">
          <h2>Ekip üyeleri</h2>
          <span>{members.length} kullanıcı</span>
        </div>
        {members.map((member) => (
          <article className="member-row" key={member.email}>
            <span>
              {member.name
                .split(" ")
                .map((part) => part[0])
                .join("")}
            </span>
            <div>
              <strong>{member.name}</strong>
              <small>{member.email}</small>
            </div>
            <em>{member.role}</em>
            <b>{member.status}</b>
          </article>
        ))}
      </section>
      <aside className="invite-panel">
        <span className="eyebrow">YENİ DAVET</span>
        <h2>Ekip arkadaşınızı davet edin</h2>
        <form onSubmit={invite} className="entity-form">
          <label>
            E-posta
            <input name="email" type="email" required />
          </label>
          <label>
            Rol
            <select name="role" defaultValue="field_sales">
              <option value="field_sales">Saha satış</option>
              <option value="team_lead">Takım lideri</option>
              <option value="regional_manager">Bölge müdürü</option>
              <option value="report_viewer">Rapor görüntüleyici</option>
            </select>
          </label>
          <button className="primary">7 günlük davet oluştur</button>
        </form>
        {message && <p className="invite-message">{message}</p>}
        {inviteUrl && (
          <div className="invite-link">
            <code>{inviteUrl}</code>
            <button
              onClick={() => void navigator.clipboard.writeText(inviteUrl)}
            >
              Kopyala
            </button>
          </div>
        )}
      </aside>
    </div>
  );
}
