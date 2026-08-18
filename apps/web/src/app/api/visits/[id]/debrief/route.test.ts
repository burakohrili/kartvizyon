import { beforeEach, describe, expect, it, vi } from "vitest";

/**
 * Bu testler tek bir davranışı sabitler: **doğrulanmamış istek için
 * `debrief_submissions` satırı yazılmaz.**
 *
 * 18 Ağustos 2026'da sıra tersti. Satır `processing` olarak yazılıyor, sonra
 * boyut/tür/kota kontrolleri erken `return` ediyordu. Bu dönüşler `try` içinde
 * olduğu için satırı `failed` yapan `catch` hiç çalışmıyor, satır sonsuza kadar
 * `processing` kalıyordu. Aynı `clientMutationId` ile her yeniden deneme 409
 * alıyor ve mobil kuyrukta o sesli not kalıcı olarak ölüyordu.
 */

type QueryResult = { data: unknown; error: unknown };

const touchedTables: string[] = [];
const results = new Map<string, QueryResult[]>();

function nextResult(table: string): QueryResult {
  const queue = results.get(table);
  if (!queue || queue.length === 0) return { data: null, error: null };
  return queue.length === 1 ? queue[0] : queue.shift()!;
}

function chain(table: string) {
  const settle = () => Promise.resolve(nextResult(table));
  const builder: Record<string, unknown> = {};
  for (const method of [
    "select",
    "eq",
    "limit",
    "upsert",
    "update",
    "insert",
    "delete",
  ]) {
    builder[method] = () => builder;
  }
  builder.single = settle;
  builder.maybeSingle = settle;
  builder.then = (resolve: (value: QueryResult) => unknown) =>
    settle().then(resolve);
  return builder;
}

const supabase = {
  auth: { getUser: async () => ({ data: { user: { id: "user-1" } } }) },
  from: (table: string) => {
    touchedTables.push(table);
    return chain(table);
  },
  storage: {
    from: () => ({ upload: async () => ({ error: null }) }),
  },
};

vi.mock("@/lib/supabase/server", () => ({
  createSupabaseServerClient: async () => supabase,
}));

vi.mock("@/lib/entitlements", () => ({
  assertQuota: async () => null,
}));

vi.mock("@/lib/openai/visit-ai", async () => {
  const actual = await vi.importActual<typeof import("@/lib/openai/visit-ai")>(
    "@/lib/openai/visit-ai",
  );
  return {
    ...actual,
    transcribeVisitAudio: async () => ({
      text: "Ziyaret sırasında konuşulanlar burada.",
      model: "test-transcribe",
    }),
    summarizeVisitTranscript: async () => ({
      summary: {
        summary: "Kısa özet metni.",
        outcome: "unknown",
        followUps: [],
      },
      model: "test-summary",
      usage: { inputTokens: 10, outputTokens: 5 },
    }),
  };
});

const { POST } = await import("./route");

const visitRow = {
  id: "00000000-0000-4000-8000-000000000001",
  workspace_id: "00000000-0000-4000-8000-000000000002",
  organization_id: null,
  representative_id: "user-1",
};

function request(body: FormData) {
  return new Request("https://app.kartvizyon.app/api/visits/x/debrief", {
    method: "POST",
    body,
  });
}

const params = Promise.resolve({ id: visitRow.id });

function formWith(audio: File | null, transcript = "") {
  const form = new FormData();
  form.set("clientMutationId", "11111111-1111-4111-8111-111111111111");
  if (transcript) form.set("transcript", transcript);
  if (audio) form.set("audio", audio);
  return form;
}

beforeEach(() => {
  touchedTables.length = 0;
  results.clear();
  results.set("visits", [{ data: visitRow, error: null }]);
});

describe("ziyaret sonrası not ucu", () => {
  it("boyutu aşan ses için 413 döner ve hiçbir gönderim satırı yazmaz", async () => {
    const oversized = new File([new Uint8Array(26 * 1024 * 1024)], "note.m4a", {
      type: "audio/mp4",
    });

    const response = await POST(request(formWith(oversized)), { params });

    expect(response.status).toBe(413);
    expect(touchedTables).not.toContain("debrief_submissions");
  });

  it("desteklenmeyen ses türü için 415 döner ve hiçbir gönderim satırı yazmaz", async () => {
    const wrongType = new File([new Uint8Array(16)], "note.bin", {
      type: "application/octet-stream",
    });

    const response = await POST(request(formWith(wrongType)), { params });

    expect(response.status).toBe(415);
    expect(touchedTables).not.toContain("debrief_submissions");
  });

  it("hâlâ süren bir işleme için 409 döner", async () => {
    results.set("debrief_submissions", [
      {
        data: { id: "sub-1", status: "processing", created_at: new Date() },
        error: null,
      },
    ]);

    const response = await POST(
      request(formWith(null, "Ziyaret notu metni burada duruyor.")),
      { params },
    );

    expect(response.status).toBe(409);
  });

  it("takılmış bir işleme satırı yeniden denemeyi engellemez", async () => {
    const stale = new Date(Date.now() - 60 * 60 * 1000);
    results.set("debrief_submissions", [
      {
        data: { id: "sub-1", status: "processing", created_at: stale },
        error: null,
      },
      { data: { id: "sub-1" }, error: null },
    ]);

    const response = await POST(
      request(formWith(null, "Ziyaret notu metni burada duruyor.")),
      { params },
    );

    expect(response.status).toBe(200);
  });
});
