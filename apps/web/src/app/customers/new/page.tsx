import { createCompany } from "./actions";
import Link from "next/link";

const errors: Record<string, string> = {
  config: "Veritabanı bağlantısı yapılandırılmadı.",
  workspace: "Çalışma alanı bulunamadı.",
  validation: "Alanları kontrol edin.",
  save: "Firma kaydedilemedi.",
};

export default async function NewCustomerPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;
  return (
    <main className="form-page">
      <section className="form-card">
        <Link href="/customers" className="back-link">
          ← Müşteriler
        </Link>
        <span className="eyebrow">YENİ KAYIT</span>
        <h1>Firma ekle</h1>
        <p>Yalnızca sahada işinize yarayan temel bilgileri girin.</p>
        {error && (
          <div className="form-message error-message">
            {errors[error] ?? "Bir hata oluştu."}
          </div>
        )}
        <form action={createCompany} className="entity-form">
          <label>
            Firma adı *
            <input
              name="name"
              minLength={2}
              maxLength={200}
              required
              autoFocus
            />
          </label>
          <div className="form-row">
            <label>
              Telefon
              <input name="phone" type="tel" />
            </label>
            <label>
              E-posta
              <input name="email" type="email" />
            </label>
          </div>
          <label>
            Web sitesi
            <input name="website" type="url" placeholder="https://" />
          </label>
          <label>
            Adres
            <textarea name="address" rows={4} maxLength={500} />
          </label>
          <div className="form-actions">
            <Link href="/customers">Vazgeç</Link>
            <button className="primary" type="submit">
              Firmayı kaydet
            </button>
          </div>
        </form>
      </section>
    </main>
  );
}
