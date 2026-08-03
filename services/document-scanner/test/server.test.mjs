import assert from "node:assert/strict";
import test from "node:test";
import { authorized, configuredAppUrl } from "../src/server.mjs";

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
