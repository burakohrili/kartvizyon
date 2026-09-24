import { writeFile } from "node:fs/promises";
const checks = [
  ["https://kartvizyon.app/", "GET", [200]],
  ["https://kartvizyon.app/privacy", "GET", [200]],
  ["https://kartvizyon.app/terms", "GET", [200]],
  ["https://kartvizyon.app/account-deletion", "GET", [200]],
  ["https://app.kartvizyon.app/login", "GET", [200]],
  ...[
    "session",
    "customers",
    "visits",
    "tasks",
    "settings/billing",
    "invitations",
    "reports/export/pdf",
  ].map((path) => [`https://app.kartvizyon.app/api/${path}`, "GET", [401]]),
  [
    "https://app.kartvizyon.app/api/internal/webhooks/revenuecat",
    "POST",
    [401],
  ],
];
const results = [];
for (const [url, method, expected] of checks) {
  try {
    const res = await fetch(url, {
      method,
      redirect: "manual",
      signal: AbortSignal.timeout(20000),
      ...(method === "POST"
        ? { body: "{}", headers: { "content-type": "application/json" } }
        : {}),
    });
    const body = await res.text();
    const item = {
      url,
      method,
      status: res.status,
      expected,
      pass: expected.includes(res.status),
    };
    if (url === "https://kartvizyon.app/") {
      const visible = body
        .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
        .replace(/<[^>]*>/g, " ")
        .replace(/\s+/g, " ");
      const individual =
        visible.match(/Bireysel Tek başına[\s\S]*?Plan bilgisi al/)?.[0] ?? "";
      item.pricing = { individual };
      results.push({
        url,
        method: "PRICING",
        pass:
          individual.includes("449") &&
          individual.includes("125") &&
          !individual.includes("Yıllık"),
        expected: "Individual monthly 449 TRY, 125 quota, no annual offer",
        actual: individual,
      });
    }
    results.push(item);
  } catch (error) {
    results.push({ url, method, pass: false, error: error.message });
  }
}
await writeFile(
  new URL("http-smoke-results.json", import.meta.url),
  JSON.stringify(
    {
      checkedAt: new Date().toISOString(),
      scope: "Deployed production only; not proof of current local worktree",
      results,
    },
    null,
    2,
  ),
);
for (const r of results)
  console.log(
    `${r.pass ? "PASS" : "FAIL"} ${r.method} ${r.url} ${r.status ?? r.error}`,
  );
process.exitCode = results.some((r) => !r.pass) ? 1 : 0;
