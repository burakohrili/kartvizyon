import Link from "next/link";
import { createSupabaseServerClient } from "@/lib/supabase/server";

/**
 * Oturumsuz ziyaretçiye "bu veriler gerçek değil" diyen ve girişe götüren şerit.
 *
 * Uygulama sayfalarının hepsi oturum yoksa demo içeriğe düşüyor. 19 Ağustos
 * 2026'da yapılan denetimde `app.kartvizyon.app/dashboard`, `/customers`,
 * `/settings/team` gibi sayfaların hiçbir çerez olmadan 200 döndüğü ve dolu bir
 * uygulama render ettiği görüldü: "Günaydın, Burak", "Vizyon Satış A.Ş.",
 * gerçek gibi duran isim ve e-posta adresleri. Sayfaların bir kısmında
 * `demo-notice` kutusu vardı, bir kısmında hiçbir uyarı yoktu ve **hiçbirinde
 * giriş bağlantısı yoktu** — ziyaretçi sahte bir uygulamanın içinde kalıyordu.
 *
 * Uyarıyı her sayfanın kendi kararına bırakmak bu duruma zaten bir kez yol
 * açtı. Bu bileşen oturumu kendisi çözer; sayfanın demo olup olmadığını
 * bilmesine gerek yoktur ve oturum varken hiçbir şey basmaz.
 *
 * Sabit konumludur çünkü sayfa düzenleri birbirinden farklı: panelin kenar
 * çubuklu ızgarasına akış içinde bir blok sokmak düzeni bozardı.
 */
export async function DemoBanner() {
  const supabase = await createSupabaseServerClient();
  if (supabase) {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (user) return null;
  }
  return (
    <aside className="demo-banner" role="status">
      <p>
        <strong>Örnek veri görüntülüyorsunuz.</strong>
        Buradaki firmalar, kişiler ve ziyaretler gerçek değildir. Kendi
        kayıtlarınızı görmek için giriş yapın.
      </p>
      <Link className="demo-banner-action" href="/login">
        Giriş yap
      </Link>
    </aside>
  );
}
