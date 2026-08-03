"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export function InviteAccept({ token }: { token: string }) {
  const router = useRouter();
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  async function accept() {
    setBusy(true);
    const response = await fetch("/api/invitations/accept", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token }),
    });
    const payload = response.status === 204 ? {} : await response.json();
    if (!response.ok) {
      setMessage(payload.error ?? "Davet kabul edilemedi.");
      setBusy(false);
      return;
    }
    router.push("/workspaces");
    router.refresh();
  }
  return (
    <div className="accept-box">
      <ul>
        <li>Onaylı ziyaret ve müşteri hafızasına erişim</li>
        <li>Rol ve bölgeyle sınırlı kurumsal görünürlük</li>
        <li>Kişisel verileriniz şirket alanına otomatik taşınmaz</li>
      </ul>
      <button className="primary" disabled={busy} onClick={() => void accept()}>
        {busy ? "Davet kabul ediliyor…" : "Daveti kabul et"}
      </button>
      {message && <p>{message}</p>}
    </div>
  );
}
