import Link from "next/link";
import { InviteAccept } from "./invite-accept";

export default async function InvitePage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const { token } = await params;
  return (
    <main className="auth-page">
      <section className="auth-card">
        <div className="auth-brand">
          <span>KV</span>
          <div>
            <strong>KartVizyon AI</strong>
            <small>Şirket çalışma alanı daveti</small>
          </div>
        </div>
        <h1>Ekibe katılın</h1>
        <p>
          Davet e-posta adresinizle giriş yaptıktan sonra şirket verilerine
          rolünüz kapsamında erişebilirsiniz.
        </p>
        {/^[a-f0-9]{64}$/i.test(token) ? (
          <InviteAccept token={token} />
        ) : (
          <div className="form-message error-message">
            Davet bağlantısı geçersiz.
          </div>
        )}
        <Link href="/login" className="invite-login-link">
          Önce giriş yapmam gerekiyor
        </Link>
      </section>
    </main>
  );
}
