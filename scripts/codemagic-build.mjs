/**
 * Codemagic build'ini REST API ile başlatır.
 *
 * Otomatik tetikleme için depoda webhook vardır (bkz. codemagic.yaml yorumları).
 * Bu betik, webhook'a bağlı olmadan build başlatmak veya iOS derlemesini
 * `submitToTestFlight=true` ile TestFlight'a göndermek için kullanılır.
 *
 * Token: Codemagic → Account settings → Integrations → Codemagic API → token üret.
 * Tokenı komut satırına yazma; ortam değişkeni olarak ver.
 *
 *   $env:CODEMAGIC_API_TOKEN = "..."            # PowerShell
 *   node scripts/codemagic-build.mjs android
 *   node scripts/codemagic-build.mjs ios
 *   node scripts/codemagic-build.mjs ios --testflight
 */

const TOKEN = process.env.CODEMAGIC_API_TOKEN;
const APP_ID = process.env.CODEMAGIC_APP_ID ?? "6a7095935947019139a67709";

const WORKFLOWS = {
  android: "kartvizyon-android-release",
  ios: "kartvizyon-ios-testflight",
};

const [target = "android", ...flags] = process.argv.slice(2);
const workflowId = WORKFLOWS[target];

if (!TOKEN) {
  console.error(
    "CODEMAGIC_API_TOKEN tanımlı değil. Codemagic → Account settings → Integrations → Codemagic API.",
  );
  process.exit(1);
}
if (!workflowId) {
  console.error(
    `Bilinmeyen hedef "${target}". Kullanılabilir: ${Object.keys(WORKFLOWS).join(", ")}`,
  );
  process.exit(1);
}

const body = {
  appId: APP_ID,
  workflowId,
  branch: process.env.CODEMAGIC_BRANCH ?? "main",
};

// iOS workflow'u submitToTestFlight girdisini taşır; bayrak verilmezse
// yalnız imzalı IPA üretilir ve TestFlight'a yükleme yapılmaz.
if (target === "ios") {
  body.inputs = { submitToTestFlight: flags.includes("--testflight") };
}

const response = await fetch("https://api.codemagic.io/builds", {
  method: "POST",
  headers: { "x-auth-token": TOKEN, "Content-Type": "application/json" },
  body: JSON.stringify(body),
});

const text = await response.text();
if (!response.ok) {
  console.error(`Build başlatılamadı (HTTP ${response.status}): ${text}`);
  process.exit(1);
}

let buildId;
try {
  buildId = JSON.parse(text).buildId;
} catch {
  buildId = null;
}

console.log(`Build başlatıldı: ${workflowId} @ ${body.branch}`);
if (target === "ios") {
  console.log(`TestFlight'a gönderim: ${body.inputs.submitToTestFlight}`);
}
if (buildId) {
  console.log(`https://codemagic.io/app/${APP_ID}/build/${buildId}`);
}
