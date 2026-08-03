"use client";

import {
  calculateVisitPriority,
  haversineDistanceKm,
} from "@kartvizyon/contracts";
import Link from "next/link";
import { useState } from "react";

const companies = [
  {
    id: "demo-1",
    name: "Atlas Medikal",
    area: "Şişli",
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
    name: "Nova Otomasyon",
    area: "Ümraniye",
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
    name: "Marmara Ambalaj",
    area: "Kağıthane",
    latitude: 41.081,
    longitude: 28.972,
    days: 93,
    overdue: 0,
    value: 0.6,
    x: 37,
    y: 20,
  },
];

export function MapExperience() {
  const [location, setLocation] = useState({
    latitude: 41.047,
    longitude: 29.006,
  });
  const [message, setMessage] = useState("Demo konumu: İstanbul merkez");
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
  function locateOnce() {
    if (!navigator.geolocation) {
      setMessage("Bu cihaz konum sorgusunu desteklemiyor.");
      return;
    }
    setLoading(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocation({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        });
        setMessage("Konum bir kez kullanıldı ve saklanmadı.");
        setLoading(false);
      },
      () => {
        setMessage("Konum izni verilmedi; demo konumuyla devam ediliyor.");
        setLoading(false);
      },
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 300000 },
    );
  }
  return (
    <div className="map-layout">
      <section className="map-canvas" aria-label="Müşteri konum haritası">
        <div className="map-grid-lines" />
        <div className="user-pin" style={{ left: "51%", top: "48%" }}>
          <span>Konumunuz</span>
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
        <div className="map-privacy">Konum geçmişi kaydedilmez</div>
      </section>
      <aside className="nearby-panel">
        <div className="nearby-heading">
          <div>
            <span className="eyebrow">ÖNCELİK SIRASI</span>
            <h2>Bugün uğranabilecekler</h2>
          </div>
          <button onClick={locateOnce} disabled={loading}>
            {loading ? "Konum alınıyor…" : "Konumumu bir kez kullan"}
          </button>
        </div>
        <p className="location-message">{message}</p>
        {candidates.map((company) => (
          <article className="candidate-card" key={company.id}>
            <div className="score-ring">{company.priority.total}</div>
            <div>
              <strong>{company.name}</strong>
              <small>
                {company.area} · {company.distanceKm.toFixed(1)} km
              </small>
              <p>
                {company.priority.reasons
                  .slice(0, 2)
                  .map((reason) => reason.label)
                  .join(" · ")}
              </p>
            </div>
            <Link href={`/customers/${company.id}`}>Brifing →</Link>
          </article>
        ))}
      </aside>
    </div>
  );
}
