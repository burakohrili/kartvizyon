import Link from "next/link";
import { MapExperience } from "./map-experience";

export default function MapPage() {
  return (
    <main className="map-page">
      <header className="map-header">
        <div>
          <Link href="/" className="back-link">
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
