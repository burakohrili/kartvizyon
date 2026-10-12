import { test } from "node:test";
import assert from "node:assert/strict";
import { validateMobileSandbox } from "./validate-mobile-sandbox.mjs";

const valid = {
  KARTVIZYON_SANDBOX_API_URL: "https://sandbox.example.test",
  SUPABASE_URL: "https://rfzmdpxnfsvatukkedrg.supabase.co",
  SUPABASE_ANON_KEY: "test-public-key",
  REVENUECAT_APPLE_PUBLIC_API_KEY: "test-public-sdk-key",
};
test("isolated staging runtime is accepted", () => {
  assert.doesNotThrow(() => validateMobileSandbox(valid));
});
test("missing or redacted configuration fails closed", () => {
  for (const key of Object.keys(valid)) {
    for (const value of ["", "[SENSITIVE]"]) {
      assert.throws(() => validateMobileSandbox({ ...valid, [key]: value }));
    }
  }
});
test("production database and API origins are rejected", () => {
  assert.throws(() =>
    validateMobileSandbox({
      ...valid,
      SUPABASE_URL: "https://nweqbfxihinuflnfolne.supabase.co",
    }),
  );
  for (const url of [
    "https://app.kartvizyon.app",
    "https://kartvizyon.app",
    "http://sandbox.example.test",
    "https://sandbox.example.test?bypass=secret",
    "https://user:secret@sandbox.example.test",
  ]) {
    assert.throws(() =>
      validateMobileSandbox({ ...valid, KARTVIZYON_SANDBOX_API_URL: url }),
    );
  }
});
