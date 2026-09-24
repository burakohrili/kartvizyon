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
  const listed = periodTotalTry(plan, period, seats);
  if (listed === null) {
    return (
      <div className="purchase-disclosure">
        <p>
          {plan.name} plan teklif usulüyle sunulur. Koltuk sayısı, dönem ve
          toplam bedel size iletilen teklifte yazılı olarak belirtilir.
        </p>
      </div>
    );
  }

  const gross =
    plan.id === "individual"
      ? listed
      : Math.round(listed * (1 + vatRate) * 100) / 100;
  const net =
    plan.id === "individual"
      ? Math.round((gross / (1 + vatRate)) * 100) / 100
      : listed;
  const vat = Math.round((gross - net) * 100) / 100;
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
            {plan.aiSummaries ? ` · Ayda ${plan.aiSummaries} AI özeti` : ""}
          </dd>
        </div>
        <div>
          <dt>Deneme</dt>
          <dd>
            İlk {TRIAL_DAYS} gün kart gerekmeden denenebilir. Otomatik ücret
            alınmaz; devam etmek için ayrıca abonelik başlatmanız gerekir. Erken
            abonelikte ücretli dönem hemen başlar.
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
            Noesis Social - Burak OHRİLİ · Ege VD. 6360302767 · +90 532 744 94
            34 · Gazi Osmanpaşa Mah. 5499/1 Sok. No:9 Bornova / İzmir
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
