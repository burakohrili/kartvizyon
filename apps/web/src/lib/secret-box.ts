import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

function encryptionKey() {
  const encoded = process.env.INTEGRATION_ENCRYPTION_KEY;
  if (!encoded) throw new Error("INTEGRATION_ENCRYPTION_KEY yapılandırılmadı.");
  const key = Buffer.from(encoded, "base64");
  if (key.length !== 32)
    throw new Error("INTEGRATION_ENCRYPTION_KEY 32 bayt Base64 olmalıdır.");
  return key;
}

export function encryptSecret(value: string) {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", encryptionKey(), iv);
  const encrypted = Buffer.concat([
    cipher.update(value, "utf8"),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();
  return [iv, tag, encrypted]
    .map((item) => item.toString("base64url"))
    .join(".");
}

export function decryptSecret(value: string) {
  const [ivPart, tagPart, encryptedPart] = value.split(".");
  if (!ivPart || !tagPart || !encryptedPart)
    throw new Error("Şifreli sır geçersiz.");
  const decipher = createDecipheriv(
    "aes-256-gcm",
    encryptionKey(),
    Buffer.from(ivPart, "base64url"),
  );
  decipher.setAuthTag(Buffer.from(tagPart, "base64url"));
  return Buffer.concat([
    decipher.update(Buffer.from(encryptedPart, "base64url")),
    decipher.final(),
  ]).toString("utf8");
}
