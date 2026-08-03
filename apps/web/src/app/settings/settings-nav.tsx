import Link from "next/link";

export function SettingsNav() {
  return (
    <nav className="settings-nav" aria-label="Ayarlar">
      <Link href="/settings/organization">Organizasyon</Link>
      <Link href="/settings/team">Ekip</Link>
      <Link href="/settings/billing">Paket ve kullanım</Link>
      <Link href="/settings/integrations">Entegrasyonlar</Link>
      <Link href="/settings/privacy">KVKK ve veri hakları</Link>
      <Link href="/settings/security">Güvenlik</Link>
    </nav>
  );
}
