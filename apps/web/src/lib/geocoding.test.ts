import { afterEach, describe, expect, it, vi } from "vitest";
import { geocodeAddress, isGeocodingConfigured } from "./geocoding";

const ADDRESS = "Gazi Osmanpaşa Mah. 5499/1 Sok. No:9 Bornova İzmir";

function mockFetch(payload: unknown, ok = true) {
  const fetchMock = vi.fn().mockResolvedValue({
    ok,
    json: async () => payload,
  });
  vi.stubGlobal("fetch", fetchMock);
  return fetchMock;
}

afterEach(() => {
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
});

describe("geocodeAddress", () => {
  it("anahtar yoksa ağa hiç çıkmaz", async () => {
    vi.stubEnv("GOOGLE_GEOCODING_API_KEY", "");
    const fetchMock = mockFetch({});
    expect(await geocodeAddress(ADDRESS)).toBeNull();
    expect(fetchMock).not.toHaveBeenCalled();
    expect(isGeocodingConfigured()).toBe(false);
  });

  it("koordinatı çözer ve Türkiye bölgesiyle sorar", async () => {
    vi.stubEnv("GOOGLE_GEOCODING_API_KEY", "test-key");
    const fetchMock = mockFetch({
      status: "OK",
      results: [{ geometry: { location: { lat: 38.4622, lng: 27.2166 } } }],
    });

    expect(await geocodeAddress(ADDRESS)).toEqual({
      latitude: 38.4622,
      longitude: 27.2166,
    });

    const requested = new URL(String(fetchMock.mock.calls[0][0]));
    expect(requested.searchParams.get("region")).toBe("tr");
    expect(requested.searchParams.get("language")).toBe("tr");
    expect(requested.searchParams.get("address")).toBe(ADDRESS);
  });

  it("çok kısa adres için kota harcamaz", async () => {
    vi.stubEnv("GOOGLE_GEOCODING_API_KEY", "test-key");
    const fetchMock = mockFetch({ status: "OK" });
    expect(await geocodeAddress("No:9")).toBeNull();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("boş ve tanımsız adresi atlar", async () => {
    vi.stubEnv("GOOGLE_GEOCODING_API_KEY", "test-key");
    mockFetch({ status: "OK" });
    expect(await geocodeAddress("   ")).toBeNull();
    expect(await geocodeAddress(undefined)).toBeNull();
    expect(await geocodeAddress(null)).toBeNull();
  });

  it("sonuç bulunamazsa null döner", async () => {
    vi.stubEnv("GOOGLE_GEOCODING_API_KEY", "test-key");
    mockFetch({ status: "ZERO_RESULTS", results: [] });
    expect(await geocodeAddress(ADDRESS)).toBeNull();
  });

  it("kota dolduğunda kaydı bozmaz", async () => {
    vi.stubEnv("GOOGLE_GEOCODING_API_KEY", "test-key");
    mockFetch({ status: "OVER_QUERY_LIMIT" });
    expect(await geocodeAddress(ADDRESS)).toBeNull();
  });

  it("ağ hatasını yutar", async () => {
    vi.stubEnv("GOOGLE_GEOCODING_API_KEY", "test-key");
    vi.stubGlobal(
      "fetch",
      vi.fn().mockRejectedValue(new Error("network down")),
    );
    expect(await geocodeAddress(ADDRESS)).toBeNull();
  });

  it("aralık dışı koordinatı reddeder", async () => {
    vi.stubEnv("GOOGLE_GEOCODING_API_KEY", "test-key");
    mockFetch({
      status: "OK",
      results: [{ geometry: { location: { lat: 999, lng: 27 } } }],
    });
    expect(await geocodeAddress(ADDRESS)).toBeNull();
  });
});
