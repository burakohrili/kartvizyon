"use client";

import { useCallback, useEffect, useState } from "react";
import {
  queuedDebriefCount,
  syncQueuedDebriefs,
} from "@/lib/offline/debrief-queue";

export function OfflineStatus() {
  const [online, setOnline] = useState(true);
  const [queued, setQueued] = useState(0);

  const refresh = useCallback(async () => {
    setOnline(navigator.onLine);
    if (!navigator.onLine) {
      const offlineOwner = localStorage.getItem("kartvizyon:offline-owner");
      if (offlineOwner) setQueued(await queuedDebriefCount(offlineOwner));
      return;
    }
    try {
      const session = await fetch("/api/session", { cache: "no-store" });
      if (!session.ok) return;
      const { ownerId } = (await session.json()) as { ownerId: string };
      localStorage.setItem("kartvizyon:offline-owner", ownerId);
      await syncQueuedDebriefs(ownerId);
      setQueued(await queuedDebriefCount(ownerId));
    } catch {
      setOnline(false);
    }
  }, []);

  useEffect(() => {
    if ("serviceWorker" in navigator) {
      void navigator.serviceWorker.register("/sw.js");
    }
    const initialRefresh = window.setTimeout(() => void refresh(), 0);
    window.addEventListener("online", refresh);
    window.addEventListener("offline", refresh);
    window.addEventListener("kartvizyon:queue-change", refresh);
    return () => {
      window.clearTimeout(initialRefresh);
      window.removeEventListener("online", refresh);
      window.removeEventListener("offline", refresh);
      window.removeEventListener("kartvizyon:queue-change", refresh);
    };
  }, [refresh]);

  if (online && queued === 0) return null;
  return (
    <aside
      className={`offline-status ${online ? "syncing" : "offline"}`}
      role="status"
    >
      {online
        ? `${queued} ziyaret notu senkronizasyon bekliyor`
        : `Çevrimdışısınız${queued ? ` · ${queued} not cihazda güvende` : ""}`}
    </aside>
  );
}
