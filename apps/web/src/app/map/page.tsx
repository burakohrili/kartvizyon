import Link from "next/link";
import { MapExperience } from "./map-experience";
import { DemoBanner } from "@/app/demo-banner";
import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export default async function MapPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).map;
  return (
    <main className="map-page">
      <DemoBanner />
      <header className="map-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.eyebrow}</span>
          <h1>{m.title}</h1>
          <p>{m.description}</p>
        </div>
      </header>
      <MapExperience locale={locale} />
    </main>
  );
}
