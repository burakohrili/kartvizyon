"use client";

import {
  calculateVisitPriority,
  haversineDistanceKm,
} from "@kartvizyon/contracts";
import Link from "next/link";
import { useState } from "react";
import type { AppLocale } from "@/lib/i18n/locale";
import { formatNumber } from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";
import { getDemoRecords } from "@/lib/i18n/demo-records";

function getCompanies(locale: AppLocale) {
  const demo = getDemoRecords(locale);
  return [
    {
      id: "demo-1",
      name: demo.companies[0],
      area: demo.areas[0].split(",")[0],
      latitude: 41.0602,
      longitude: 28.9877,
      days: 48,
      overdue: 2,
      value: 0.8,
      x: 44,
      y: 35,
    },
    {
      id: "demo-2",
      name: demo.companies[1],
      area: demo.areas[1].split(",")[0],
      latitude: 41.0256,
      longitude: 29.0963,
      days: 21,
      overdue: 1,
      value: 0.7,
      x: 73,
      y: 45,
    },
    {
      id: "demo-3",
      name: demo.companies[2],
      area: demo.areas[2].split(",")[0],
      latitude: 41.081,
      longitude: 28.972,
      days: 93,
      overdue: 0,
      value: 0.6,
      x: 37,
      y: 20,
    },
  ];
}

export function MapExperience({ locale }: { locale: AppLocale }) {
  const m = getMessages(locale).map;
  const companies = getCompanies(locale);
  const [location, setLocation] = useState({
    latitude: 41.047,
    longitude: 29.006,
  });
  const [message, setMessage] = useState<string>(m.demoLocation);
  const [loading, setLoading] = useState(false);
  const candidates = companies
    .map((company) => {
      const distanceKm = haversineDistanceKm(location, company);
      return {
        ...company,
        distanceKm,
        priority: calculateVisitPriority({
          daysSinceVisit: company.days,
          overdueTaskCount: company.overdue,
          customerValue: company.value,
          distanceKm,
        }),
      };
    })
    .sort((a, b) => b.priority.total - a.priority.total);
  function localizedReason(
    reason: (typeof candidates)[number]["priority"]["reasons"][number],
    company: (typeof candidates)[number],
  ) {
    switch (reason.code) {
      case "no-visit":
        return m.noVisits;
      case "last-visit":
        return m.lastVisit.replace(
          "{days}",
          formatNumber(company.days, locale),
        );
      case "overdue-follow-ups":
        return m.overdueFollowups.replace(
          "{count}",
          formatNumber(company.overdue, locale),
        );
      case "customer-value":
        return m.customerValue;
      case "distance":
        return m.distance.replace(
          "{distance}",
          new Intl.NumberFormat(locale === "en" ? "en-US" : "tr-TR", {
            minimumFractionDigits: 1,
            maximumFractionDigits: 1,
          }).format(company.distanceKm),
        );
    }
  }
  function locateOnce() {
    if (!navigator.geolocation) {
      setMessage(m.unsupported);
      return;
    }
    setLoading(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocation({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        });
        setMessage(m.locationUsed);
        setLoading(false);
      },
      () => {
        setMessage(m.permissionDenied);
        setLoading(false);
      },
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 300000 },
    );
  }
  return (
    <div className="map-layout">
      <section className="map-canvas" aria-label={m.canvasLabel}>
        <div className="map-grid-lines" />
        <div className="user-pin" style={{ left: "51%", top: "48%" }}>
          <span>{m.yourLocation}</span>
        </div>
        {candidates.map((company) => (
          <Link
            href={`/customers/${company.id}`}
            className={`customer-pin ${company.priority.total >= 70 ? "high" : ""}`}
            style={{ left: `${company.x}%`, top: `${company.y}%` }}
            key={company.id}
            aria-label={`${company.name}, öncelik ${company.priority.total}`}
          >
            <span>{company.priority.total}</span>
            <small>{company.name}</small>
          </Link>
        ))}
        <div className="map-privacy">{m.noLocationHistory}</div>
      </section>
      <aside className="nearby-panel">
        <div className="nearby-heading">
          <div>
            <span className="eyebrow">{m.priority}</span>
            <h2>{m.visitToday}</h2>
          </div>
          <button onClick={locateOnce} disabled={loading}>
            {loading ? m.locating : m.useLocation}
          </button>
        </div>
        <p className="location-message">{message}</p>
        {candidates.map((company) => (
          <article className="candidate-card" key={company.id}>
            <div className="score-ring">{company.priority.total}</div>
            <div>
              <strong>{company.name}</strong>
              <small>
                {company.area} ·{" "}
                {new Intl.NumberFormat(locale === "en" ? "en-US" : "tr-TR", {
                  minimumFractionDigits: 1,
                  maximumFractionDigits: 1,
                }).format(company.distanceKm)}{" "}
                km
              </small>
              <p>
                {company.priority.reasons
                  .slice(0, 2)
                  .map((reason) => localizedReason(reason, company))
                  .join(" · ")}
              </p>
            </div>
            <Link href={`/customers/${company.id}`}>{m.briefing}</Link>
          </article>
        ))}
      </aside>
    </div>
  );
}
