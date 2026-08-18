import { beforeEach, describe, expect, it, vi } from "vitest";

/**
 * Karantinadaki dosya taranmadan indirilemez. Bu ucun tek kritik davranışı
 * budur: `scan_status` `clean` değilse imzalı bağlantı hiç üretilmez.
 */

const document = {
  current: {
    storage_path: "user-1/liste.pdf",
    scan_status: "clean",
    file_name: "liste.pdf",
  } as Record<string, unknown> | null,
};
const signedUrls: string[] = [];

function documentQuery() {
  const builder = {
    select: () => builder,
    eq: () => builder,
    single: async () =>
      document.current
        ? { data: document.current, error: null }
        : { data: null, error: { message: "yok" } },
  };
  return builder;
}

vi.mock("@/lib/api-context", () => ({
  getApiContext: async () => ({
    ok: true as const,
    user: { id: "user-1" },
    workspaceId: "workspace-1",
    organizationId: null,
    supabase: {
      from: () => documentQuery(),
      storage: {
        from: () => ({
          createSignedUrl: async (path: string) => {
            signedUrls.push(path);
            return {
              data: { signedUrl: `https://storage.example/${path}?token=x` },
              error: null,
            };
          },
        }),
      },
    },
  }),
}));

const { GET } = await import("./route");

const id = "11111111-1111-4111-8111-111111111111";
const params = Promise.resolve({ id });

function request(accept?: string) {
  return new Request(
    `https://app.kartvizyon.app/api/documents/${id}/download`,
    {
      headers: accept ? { accept } : {},
    },
  );
}

beforeEach(() => {
  signedUrls.length = 0;
  document.current = {
    storage_path: "user-1/liste.pdf",
    scan_status: "clean",
    file_name: "liste.pdf",
  };
});

describe("belge indirme", () => {
  it("taraması temiz olmayan belge için bağlantı üretmez", async () => {
    document.current = {
      storage_path: "user-1/liste.pdf",
      scan_status: "pending",
      file_name: "liste.pdf",
    };

    const response = await GET(request("application/json"), { params });

    expect(response.status).toBe(409);
    expect(signedUrls).toHaveLength(0);
  });

  it("engellenmiş belge için bağlantı üretmez", async () => {
    document.current = {
      storage_path: "user-1/zararli.pdf",
      scan_status: "blocked",
      file_name: "zararli.pdf",
    };

    const response = await GET(request("application/json"), { params });

    expect(response.status).toBe(409);
    expect(signedUrls).toHaveLength(0);
  });

  it("JSON isteyen istemciye bağlantıyı gövdede verir", async () => {
    // Mobil istemci 303'ü kullanamaz; `http` paketi yönlendirmeyi izleyip
    // dosyayı JSON diye çözmeye çalışır.
    const response = await GET(request("application/json"), { params });

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.url).toContain("token=x");
    expect(body.fileName).toBe("liste.pdf");
  });

  it("tarayıcıya yönlendirme döner", async () => {
    const response = await GET(request(), { params });

    expect(response.status).toBe(303);
  });

  it("başka çalışma alanının belgesi bulunamaz", async () => {
    document.current = null;

    const response = await GET(request("application/json"), { params });

    expect(response.status).toBe(404);
    expect(signedUrls).toHaveLength(0);
  });
});
