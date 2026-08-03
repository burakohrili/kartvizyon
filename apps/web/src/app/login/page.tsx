import { signIn, signUp } from "./actions";

const messages: Record<string, string> = {
  config: "Supabase ortam değişkenleri henüz yapılandırılmadı.",
  credentials: "E-posta veya şifre hatalı.",
  signup: "Hesap oluşturulamadı. Bilgileri kontrol edin.",
};

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; message?: string }>;
}) {
  const query = await searchParams;
  return (
    <main className="auth-page">
      <section className="auth-card">
        <div className="auth-brand">
          <span>KV</span>
          <div>
            <strong>KartVizyon AI</strong>
            <small>Saha müşteri hafızası</small>
          </div>
        </div>
        <h1>Tekrar hoş geldiniz</h1>
        <p>Ziyaretlerinize kaldığınız yerden devam edin.</p>
        {query.error && (
          <div className="form-message error-message">
            {messages[query.error] ?? "Bir hata oluştu."}
          </div>
        )}
        {query.message === "verify" && (
          <div className="form-message success-message">
            Doğrulama bağlantısı e-posta adresinize gönderildi.
          </div>
        )}
        <form action={signIn} className="auth-form">
          <label>
            E-posta
            <input name="email" type="email" autoComplete="email" required />
          </label>
          <label>
            Şifre
            <input
              name="password"
              type="password"
              autoComplete="current-password"
              minLength={8}
              required
            />
          </label>
          <button className="primary" type="submit">
            Giriş yap
          </button>
        </form>
        <details>
          <summary>Yeni hesap oluştur</summary>
          <form action={signUp} className="auth-form signup-form">
            <label>
              Ad soyad
              <input name="fullName" minLength={2} maxLength={120} required />
            </label>
            <label>
              E-posta
              <input name="email" type="email" autoComplete="email" required />
            </label>
            <label>
              Şifre
              <input
                name="password"
                type="password"
                autoComplete="new-password"
                minLength={8}
                required
              />
            </label>
            <button className="secondary light" type="submit">
              Ücretsiz hesap oluştur
            </button>
          </form>
        </details>
        <small className="privacy-note">
          AI tarafından oluşturulan kayıtlar onayınız olmadan yöneticilerle
          paylaşılmaz.
        </small>
      </section>
    </main>
  );
}
