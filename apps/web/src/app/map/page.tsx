import Link from "next/link";
import { MapExperience } from "./map-experience";
import { DemoBanner } from "@/app/demo-banner";

export default function MapPage() {
  return (
    <main className="map-page">
      <DemoBanner />
      <header className="map-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">BÖLGE GÖRÜNÜMÜ</span>
          <h1>Yakındaki müşteriler</h1>
          <p>
            Konum yalnızca bu sorgu için cihazda kullanılır; sürekli takip
            edilmez.
          </p>
        </div>
      </header>
      <MapExperience />
    </main>
  );
}
