import Link from "next/link";
import { ContactForm } from "./contact-form";

export default async function NewContactPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return (
    <main className="form-page">
      <section className="form-card">
        <Link href={`/customers/${id}`} className="back-link">
          ← Firma detayına dön
        </Link>
        <span className="eyebrow">İLGİLİ KİŞİ</span>
        <h1>Kişi ekle</h1>
        <p>
          Kartviziti tarayın veya iletişim bilgilerini elle girin. AI çıktısı
          doğrudan kaydedilmez.
        </p>
        <ContactForm companyId={id} />
      </section>
    </main>
  );
}
