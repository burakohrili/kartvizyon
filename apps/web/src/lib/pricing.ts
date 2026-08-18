/**
 * Fiyatların tek kaynağı.
 *
 * Rakamlar ADR-0005'te karara bağlanmıştır. Pazarlama sayfası, mesafeli satış
 * sözleşmesi, ödeme öncesi bilgilendirme ve ileride eklenecek iyzico checkout
 * aynı değerleri buradan okur; `packages/database/migrations/0021_entitlements.up.sql`
 * plan tohumları da bu tabloyla eşleşmelidir.
 */

export type PublicPlan = {
  id: "free" | "individual" | "team" | "enterprise";
  name: string;
  audience: string;
  /** Aylık, KDV hariç ₺. null = teklif usulü. */
  monthlyTry: number | null;
  /** Yıllık toplam, KDV hariç ₺ (iki ay bedava). null = teklif usulü. */
  annualTry: number | null;
  /** Fiyat koltuk başına mı, çalışma alanı başına mı? */
  perSeat: boolean;
  minSeats: number;
  /** Koltuk başına aylık AI dakikası. */
  aiMinutes: number;
  /** Koltuk başına aylık kartvizit taraması. null = sınırsız. */
  ocr: number | null;
  /** Çalışma alanı başına müşteri sınırı. null = sınırsız. */
  companies: number | null;
  highlight?: boolean;
  note?: string;
  items: string[];
};

export const TRIAL_DAYS = 14;

/** Mağaza komisyonu (%15) telafi edildiği için mobil fiyat webden yüksektir. */
export const IAP_INDIVIDUAL_MONTHLY_TRY = 449;

export const PUBLIC_PLANS: PublicPlan[] = [
  {
    id: "individual",
    name: "Bireysel",
    audience: "Tek başına saha çalışan profesyoneller için",
    monthlyTry: 349,
    annualTry: 3490,
    perSeat: false,
    minSeats: 1,
    aiMinutes: 120,
    ocr: 60,
    companies: null,
    items: [
      "Sınırsız müşteri ve ziyaret kaydı",
      "Ayda 120 AI dakikası, 60 kartvizit taraması",
      "Offline mobil kullanım",
      "Kişisel takip ve hatırlatmalar",
    ],
  },
  {
    id: "team",
    name: "Ekip",
    audience: "Büyüyen saha satış ekipleri için",
    monthlyTry: 279,
    annualTry: 2790,
    perSeat: true,
    minSeats: 3,
    aiMinutes: 150,
    ocr: 80,
    companies: null,
    highlight: true,
    note: "En az 3 koltuk · AI kotası ekip havuzunda toplanır",
    items: [
      "Bireysel plandaki her şey",
      "Koltuk başına 150 AI dakikası (havuzlanmış)",
      "Rol bazlı yetkilendirme ve ekip davetleri",
      "Yönetici raporları ve paylaşılabilir bağlantılar",
    ],
  },
  {
    id: "enterprise",
    name: "Kurumsal",
    audience: "Bölge/takım yapısı olan organizasyonlar için",
    monthlyTry: 449,
    annualTry: null,
    perSeat: true,
    minSeats: 10,
    aiMinutes: 250,
    ocr: null,
    companies: null,
    note: "En az 10 koltuk · Yıllık sözleşme teklif usulüdür",
    items: [
      "Ekip plandaki her şey",
      "Koltuk başına 250 AI dakikası, sınırsız tarama",
      "Bölge/takım yönetimi ve entegrasyon webhookları",
      "Genişletilmiş audit log ve öncelikli destek",
    ],
  },
];

export const FREE_TIER = {
  name: "Ücretsiz",
  companies: 5,
  aiMinutes: 10,
  ocr: 5,
  seats: 1,
};

export type TopUpPackage = {
  id: "ai_100" | "ai_300" | "ai_1000";
  name: string;
  detail: string;
  aiMinutes: number;
  ocr: number;
  priceTry: number;
};

export const TOP_UP_PACKAGES: TopUpPackage[] = [
  {
    id: "ai_100",
    name: "AI 100",
    detail: "+100 dakika, +50 tarama",
    aiMinutes: 100,
    ocr: 50,
    priceTry: 149,
  },
  {
    id: "ai_300",
    name: "AI 300",
    detail: "+300 dakika, +150 tarama",
    aiMinutes: 300,
    ocr: 150,
    priceTry: 349,
  },
  {
    id: "ai_1000",
    name: "AI 1000",
    detail: "+1000 dakika, +500 tarama",
    aiMinutes: 1000,
    ocr: 500,
    priceTry: 899,
  },
];

const formatter = new Intl.NumberFormat("tr-TR", {
  style: "currency",
  currency: "TRY",
  maximumFractionDigits: 0,
});

export function formatTry(amount: number): string {
  return formatter.format(amount);
}

/** Satın alma ekranında gösterilecek dönemsel toplam bedel. */
export function periodTotalTry(
  plan: PublicPlan,
  period: "monthly" | "annual",
  seats: number,
): number | null {
  const unit = period === "monthly" ? plan.monthlyTry : plan.annualTry;
  if (unit === null) return null;
  const effectiveSeats = plan.perSeat ? Math.max(seats, plan.minSeats) : 1;
  return unit * effectiveSeats;
}
