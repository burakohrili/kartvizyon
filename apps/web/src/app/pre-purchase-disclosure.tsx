import Link from "next/link";
import {
  formatTry,
  periodTotalTry,
  TRIAL_DAYS,
  type PublicPlan,
} from "@/lib/pricing";

/**
 * Ödeme öncesi zorunlu bilgilendirme.
 *
 * 6502 sayılı Kanun ve Mesafeli Sözleşmeler Yönetmeliği, tüketiciden ödeme
 * yükümlülüğü doğuran onay alınmadan önce hizmetin niteliğini, toplam bedeli
 * (vergiler dâhil), ödeme ve yenileme koşullarını ve cayma hakkını açık şekilde
 * göstermeyi zorunlu tutar. Bu bileşen iyzico checkout ekranına bağlanacaktır;
 * şimdilik sözleşme sayfalarında örnek/önizleme olarak da kullanılabilir.
 */
export function PrePurchaseDisclosure({
  plan,
  period,
  seats,
  vatRate = 0.2,
}: {
  plan: PublicPlan;
  period: "monthly" | "annual";
  seats: number;
  vatRate?: number;
}) {
  const net = periodTotalTry(plan, period, seats);
  if (net === null) {
    return (
      <div className="purchase-disclosure">
        <p>
          {plan.name} plan teklif usulüyle sunulur. Koltuk sayısı, dönem ve
          toplam bedel size iletilen teklifte yazılı olarak belirtilir.
        </p>
      </div>
    );
  }

  const vat = Math.round(net * vatRate);
  const gross = net + vat;
  const periodLabel = period === "monthly" ? "aylık" : "yıllık";
  const effectiveSeats = plan.perSeat ? Math.max(seats, plan.minSeats) : 1;

  return (
    <div className="purchase-disclosure">
      <h3>Ödeme öncesi bilgilendirme</h3>
      <dl>
        <div>
          <dt>Hizmet</dt>
          <dd>
            KartVizyon {plan.name} planı — süreli yazılım aboneliği
            {plan.perSeat ? ` · ${effectiveSeats} koltuk` : ""}
          </dd>
        </div>
        <div>
          <dt>Abonelik dönemi</dt>
          <dd>{periodLabel}, dönem sonunda otomatik yenilenir</dd>
        </div>
        <div>
          <dt>Ara toplam (KDV hariç)</dt>
          <dd>{formatTry(net)}</dd>
        </div>
        <div>
          <dt>KDV (%{Math.round(vatRate * 100)})</dt>
          <dd>{formatTry(vat)}</dd>
        </div>
        <div>
          <dt>Tahsil edilecek toplam</dt>
          <dd>
            <strong>{formatTry(gross)}</strong> / {periodLabel}
          </dd>
        </div>
        <div>
          <dt>Kapsam</dt>
          <dd>
            {plan.companies === null
              ? "Sınırsız müşteri"
              : `${plan.companies} müşteri`}
            {" · "}
            {plan.aiMinutes} AI dakikası
            {plan.perSeat ? " / koltuk (havuzlanmış)" : ""}
            {" · "}
            {plan.ocr === null ? "Sınırsız tarama" : `${plan.ocr} tarama`}
          </dd>
        </div>
        <div>
          <dt>Deneme</dt>
          <dd>
            İlk {TRIAL_DAYS} gün ücretsizdir; deneme süresi bitmeden iptal
            ederseniz ücret tahsil edilmez.
          </dd>
        </div>
        <div>
          <dt>İptal</dt>
          <dd>
            Yenilemeyi istediğiniz zaman durdurabilirsiniz; iptal mevcut dönemin
            sonunda yürürlüğe girer.
          </dd>
        </div>
        <div>
          <dt>Satıcı</dt>
          <dd>
            Noesis Social - Burak OHRİLİ · Ege VD. 35509755908 · Gazi Osmanpaşa
            Mah. 5499/1 Sok. No:9 Bornova / İzmir
          </dd>
        </div>
      </dl>
      <p className="purchase-disclosure-links">
        Onaylayarak{" "}
        <Link href="/distance-sales">Mesafeli Satış Sözleşmesi</Link> ve{" "}
        <Link href="/delivery-refund">Teslim, İptal ve İade Koşulları</Link>
        &apos;nı kabul etmiş olursunuz.
      </p>
    </div>
  );
}
