import Link from "next/link";

import { createCompany } from "./actions";

const errors: Record<string, string> = {
  config: "Veritabanı bağlantısı yapılandırılmadı.",
  workspace: "Çalışma alanı bulunamadı.",
  validation: "Alanları kontrol edin.",
  save: "Firma kaydedilemedi.",
  contact: "Firma yetkilisi kaydedilemedi. Lütfen tekrar deneyin.",
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
        <p>Firma ve varsa ilgili kişi bilgilerini girin.</p>
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
              Firma telefonu
              <input name="phone" type="tel" maxLength={40} />
            </label>
            <label>
              Firma e-postası
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

          <div className="form-section">
            <h2>Firma yetkilisi</h2>
            <p>
              İlgili kişi bilgileri isteğe bağlıdır. Bir alan doldurursanız ad
              alanı zorunludur.
            </p>
            <div className="form-row">
              <label>
                Ad
                <input name="contactFirstName" maxLength={100} />
              </label>
              <label>
                Soyad
                <input name="contactLastName" maxLength={100} />
              </label>
            </div>
            <label>
              Unvan
              <input name="contactTitle" maxLength={120} />
            </label>
            <div className="form-row">
              <label>
                Yetkili telefonu
                <input name="contactPhone" type="tel" maxLength={40} />
              </label>
              <label>
                Yetkili e-postası
                <input name="contactEmail" type="email" />
              </label>
            </div>
          </div>

          <div className="form-actions">
            <Link href="/customers">Vazgeç</Link>
            <button className="primary" type="submit">
              Firma ve yetkiliyi kaydet
            </button>
          </div>
        </form>
      </section>
    </main>
  );
}
