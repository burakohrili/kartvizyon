"use client";

import { useState, type FormEvent } from "react";
import type { AppLocale } from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";
import { getDemoRecords } from "@/lib/i18n/demo-records";

export function TeamManager({
  organizationId,
  locale,
}: {
  organizationId: string;
  locale: AppLocale;
}) {
  const m = getMessages(locale).workspaceAdmin;
  const demo = getDemoRecords(locale);
  const members = demo.teamMembers.map((name, index) => ({
    name,
    email: demo.teamEmails[index],
    role: ["owner", "fieldSales", "teamLead"][index],
    status: "active",
  }));
  const [inviteUrl, setInviteUrl] = useState("");
  const [message, setMessage] = useState("");
  async function invite(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    setMessage(m.preparingInvitation);
    const expiresAt = new Date(Date.now() + 7 * 86_400_000).toISOString();
    try {
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
        setMessage(m.demoInvite);
        return;
      }
      if (!response.ok) {
        setMessage(m.inviteFailed);
        return;
      }
      const payload = await response.json();
      setInviteUrl(payload.data.inviteUrl);
      setMessage(m.inviteCreated);
    } catch {
      setMessage(m.inviteFailed);
    }
  }
  return (
    <div className="team-layout">
      <section className="team-panel">
        <div className="detail-heading">
          <h2>{m.teamMembers}</h2>
          <span>
            {members.length} {m.users}
          </span>
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
            <em>
              {member.role === "owner"
                ? m.owner
                : member.role === "fieldSales"
                  ? m.fieldSales
                  : m.teamLead}
            </em>
            <b>{m.active}</b>
          </article>
        ))}
      </section>
      <aside className="invite-panel">
        <span className="eyebrow">{m.inviteEyebrow}</span>
        <h2>{m.inviteTitle}</h2>
        <form onSubmit={invite} className="entity-form">
          <label>
            {m.email}
            <input name="email" type="email" required />
          </label>
          <label>
            {m.role}
            <select name="role" defaultValue="field_sales">
              <option value="field_sales">{m.fieldSales}</option>
              <option value="team_lead">{m.teamLead}</option>
              <option value="regional_manager">{m.regionalManager}</option>
              <option value="report_viewer">{m.reportViewer}</option>
            </select>
          </label>
          <button className="primary">{m.createInvitation}</button>
        </form>
        {message && <p className="invite-message">{message}</p>}
        {inviteUrl && (
          <div className="invite-link">
            <code>{inviteUrl}</code>
            <button
              onClick={() => {
                void navigator.clipboard
                  .writeText(inviteUrl)
                  .then(() => setMessage(m.copied))
                  .catch(() => setMessage(m.copyFailed));
              }}
            >
              {m.copy}
            </button>
          </div>
        )}
      </aside>
    </div>
  );
}
