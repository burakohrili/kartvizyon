"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { getMessages } from "@/lib/i18n/messages";
import type { AppLocale } from "@/lib/i18n/locale";

export function InviteAccept({
  token,
  locale,
}: {
  token: string;
  locale: AppLocale;
}) {
  const messages = getMessages(locale).auth;
  const router = useRouter();
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  async function accept() {
    setBusy(true);
    try {
      const response = await fetch("/api/invitations/accept", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token }),
      });
      if (!response.ok) {
        setMessage(messages.inviteFailed);
        return;
      }
      router.push("/workspaces");
      router.refresh();
    } catch {
      setMessage(messages.inviteFailed);
    } finally {
      setBusy(false);
    }
  }
  return (
    <div className="accept-box">
      <ul>
        {messages.inviteBenefits.map((benefit) => (
          <li key={benefit}>{benefit}</li>
        ))}
      </ul>
      <button className="primary" disabled={busy} onClick={() => void accept()}>
        {busy ? messages.inviteAccepting : messages.acceptInvite}
      </button>
      {message && <p>{message}</p>}
    </div>
  );
}
