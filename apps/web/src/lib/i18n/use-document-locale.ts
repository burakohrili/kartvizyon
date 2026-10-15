"use client";

import { useSyncExternalStore } from "react";
import type { AppLocale } from "./locale";

function subscribe(callback: () => void) {
  const observer = new MutationObserver(callback);
  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ["lang"],
  });
  return () => observer.disconnect();
}

function getSnapshot(): AppLocale {
  return document.documentElement.lang === "en" ? "en" : "tr";
}

function getServerSnapshot(): AppLocale {
  return "tr";
}

export function useDocumentLocale() {
  return useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);
}
