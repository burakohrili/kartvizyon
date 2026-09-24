import assert from "node:assert/strict";
import test from "node:test";
import {
  appRequestHeaders,
  authorized,
  configuredAppUrl,
} from "../src/server.mjs";

test("Bearer sırrını sabit zamanlı karşılaştırır", () => {
  assert.equal(
    authorized(
      { headers: { authorization: "Bearer scanner-secret" } },
      "scanner-secret",
    ),
    true,
  );
  assert.equal(
    authorized(
      { headers: { authorization: "Bearer wrong" } },
      "scanner-secret",
    ),
    false,
  );
  assert.equal(authorized({ headers: {} }, "scanner-secret"), false);
});

test("callback hedefi production ortamında HTTPS olmak zorundadır", () => {
  assert.equal(
    configuredAppUrl("https://kartvizyon.app").origin,
    "https://kartvizyon.app",
  );
  assert.equal(
    configuredAppUrl("http://localhost:3000").origin,
    "http://localhost:3000",
  );
  assert.throws(() => configuredAppUrl("http://example.com"), /HTTPS/);
  assert.throws(() => configuredAppUrl(""), /tanımlı değil/);
});

test("korumalı Preview callback'ine yalnız yapılandırılmış bypass başlığını ekler", () => {
  const previous = process.env.VERCEL_AUTOMATION_BYPASS_SECRET;
  try {
    delete process.env.VERCEL_AUTOMATION_BYPASS_SECRET;
    assert.deepEqual(appRequestHeaders({ authorization: "Bearer scan" }), {
      authorization: "Bearer scan",
    });

    process.env.VERCEL_AUTOMATION_BYPASS_SECRET = "preview-bypass";
    assert.deepEqual(appRequestHeaders({ authorization: "Bearer scan" }), {
      authorization: "Bearer scan",
      "x-vercel-protection-bypass": "preview-bypass",
    });
  } finally {
    if (previous === undefined)
      delete process.env.VERCEL_AUTOMATION_BYPASS_SECRET;
    else process.env.VERCEL_AUTOMATION_BYPASS_SECRET = previous;
  }
});
