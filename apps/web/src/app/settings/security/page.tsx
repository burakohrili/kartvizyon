import Link from "next/link";
import { signOutEverywhere } from "./actions";
import { DemoBanner } from "@/app/demo-banner";

export default function SecuritySettingsPage() {
  return (
    <main className="form-page">
      <DemoBanner />
      <section className="form-card security-card">
        <Link href="/dashboard" className="back-link">
          ← Genel bakış
        </Link>
        <span className="eyebrow">HESAP GÜVENLİĞİ</span>
        <h1>Oturumlar ve cihazlar</h1>
        <p>
          Kaybolan veya artık kullanmadığınız cihazların erişimini tek işlemle
          kaldırın.
        </p>
        <section className="security-action">
          <div>
            <strong>Tüm cihazlardan çıkış yap</strong>
            <p>
              Web ve mobil dahil bütün yenileme tokenları iptal edilir. Bu
              cihazda da yeniden giriş gerekir.
            </p>
          </div>
          <form action={signOutEverywhere}>
            <button className="danger-button">Tüm oturumları kapat</button>
          </form>
        </section>
        <p className="security-note">
          İşlem güvenlik audit kaydına eklenir. Offline kuyruktaki notlar başka
          kullanıcı hesabına gönderilmez.
        </p>
      </section>
    </main>
  );
}
