/**
 * Build sonrası sır sızıntısı denetimi.
 *
 * Next.js yalnız `NEXT_PUBLIC_` önekli değişkenleri istemci paketine gömer.
 * Ancak bir sunucu değişkeni yanlışlıkla bir client component'a taşınırsa
 * derleme hata vermez — değer sessizce tarayıcıya iner. Bu betik derlenmiş
 * istemci varlıklarını tarayarak bunu yakalar.
 *
 * `npm run check` içinde build'den sonra çalışır.
 */
import { readdir, readFile, stat } from "node:fs/promises";
import { join, resolve } from "node:path";

const clientRoot = resolve(import.meta.dirname, "../.next/static");

/** İstemciye asla inmemesi gereken ortam değişkenleri. */
const SERVER_ONLY_VARS = [
  "SUPABASE_SERVICE_ROLE_KEY",
  "OPENAI_API_KEY",
  "CRON_SECRET",
  "DOCUMENT_SCAN_SECRET",
  "INTEGRATION_ENCRYPTION_KEY",
  "PRIVACY_WORKER_SECRET",
  "WEBHOOK_WORKER_SECRET",
  "RESEND_API_KEY",
  "SENTRY_AUTH_TOKEN",
];

/** Değer biçimine göre sır kalıpları (değişken adı geçmese bile yakalar). */
const SECRET_PATTERNS = [
  { name: "OpenAI anahtarı", pattern: /\bsk-[A-Za-z0-9_-]{20,}/ },
  { name: "Supabase service_role JWT", pattern: /"role"\s*:\s*"service_role"/ },
  { name: "Resend anahtarı", pattern: /\bre_[A-Za-z0-9]{20,}/ },
  { name: "Özel anahtar bloğu", pattern: /-----BEGIN [A-Z ]*PRIVATE KEY-----/ },
];

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = await Promise.all(
    entries.map(async (entry) => {
      const full = join(directory, entry.name);
      if (entry.isDirectory()) return collectFiles(full);
      return [full];
    }),
  );
  return files.flat();
}

let root;
try {
  root = await stat(clientRoot);
} catch {
  console.error(
    "Derlenmiş istemci varlıkları bulunamadı. Önce `npm run build` çalıştırın.",
  );
  process.exit(1);
}
if (!root.isDirectory()) process.exit(1);

const files = (await collectFiles(clientRoot)).filter((file) =>
  /\.(js|mjs|css|json|map)$/.test(file),
);

const findings = [];
for (const file of files) {
  const content = await readFile(file, "utf8");
  for (const variable of SERVER_ONLY_VARS) {
    const value = process.env[variable];
    // Değişken adının geçmesi tek başına sızıntı değildir (ör. hata mesajı);
    // asıl tehlike gerçek değerin gömülmüş olmasıdır.
    if (value && value.length > 12 && content.includes(value)) {
      findings.push(`${file}: ${variable} DEĞERİ istemci paketinde`);
    }
  }
  for (const { name, pattern } of SECRET_PATTERNS) {
    if (pattern.test(content)) {
      findings.push(`${file}: ${name} kalıbı eşleşti`);
    }
  }
}

if (findings.length > 0) {
  console.error("Sır sızıntısı bulundu:");
  for (const finding of findings) console.error(`  - ${finding}`);
  process.exit(1);
}

console.log(`${files.length} istemci varlığı tarandı; sunucu sırrı bulunmadı.`);
