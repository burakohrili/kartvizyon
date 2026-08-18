/**
 * Adres metnini koordinata çevirir.
 *
 * Elle girilen müşterinin koordinatı olmadığı için yakınlık hatırlatması hiç
 * çalışmıyordu. Burada üretilen koordinat bir *tahmindir*; saha çalışanı
 * müşterinin kapısında "konumu sabitle" derse o değer bunu ezer
 * (`companies.location_source`, migration 0022).
 *
 * Anahtar tanımlı değilse sessizce atlanır — geocoding hiçbir zaman müşteri
 * kaydını engellememelidir.
 */

export type Coordinates = { latitude: number; longitude: number };

const ENDPOINT = "https://maps.googleapis.com/maps/api/geocode/json";

/** Google'ın ücretsiz kotasını boş yere harcamamak için en kısa anlamlı adres. */
const MIN_ADDRESS_LENGTH = 8;

type GeocodeResponse = {
  status?: string;
  results?: { geometry?: { location?: { lat?: number; lng?: number } } }[];
};

export function isGeocodingConfigured(): boolean {
  return Boolean(process.env.GOOGLE_GEOCODING_API_KEY);
}

export async function geocodeAddress(
  address: string | undefined | null,
): Promise<Coordinates | null> {
  const key = process.env.GOOGLE_GEOCODING_API_KEY;
  const trimmed = address?.trim();
  if (!key || !trimmed || trimmed.length < MIN_ADDRESS_LENGTH) return null;

  const url = new URL(ENDPOINT);
  url.searchParams.set("address", trimmed);
  url.searchParams.set("key", key);
  // Türkiye adreslerinde doğruluğu belirgin biçimde artırır.
  url.searchParams.set("region", "tr");
  url.searchParams.set("language", "tr");

  try {
    const response = await fetch(url, {
      // Adres kaydı bekleyen kullanıcıyı geciktirmemek için kısa tutulur.
      signal: AbortSignal.timeout(4000),
    });
    if (!response.ok) return null;

    const payload = (await response.json()) as GeocodeResponse;
    if (payload.status !== "OK") return null;

    const location = payload.results?.[0]?.geometry?.location;
    const latitude = location?.lat;
    const longitude = location?.lng;
    if (typeof latitude !== "number" || typeof longitude !== "number") {
      return null;
    }
    if (
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180
    ) {
      return null;
    }
    return { latitude, longitude };
  } catch {
    // Zaman aşımı, ağ hatası veya kota dolması müşteri kaydını bozmamalıdır.
    return null;
  }
}
