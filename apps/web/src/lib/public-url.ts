import { resolve4, resolve6 } from "node:dns/promises";
import { isIP } from "node:net";

export function isPrivateAddress(address: string) {
  if (
    address === "::1" ||
    address.startsWith("fe80:") ||
    address.startsWith("fc") ||
    address.startsWith("fd")
  )
    return true;
  if (!address.includes(".")) return false;
  const [a, b] = address.split(".").map(Number);
  return (
    a === 10 ||
    a === 127 ||
    a === 0 ||
    (a === 169 && b === 254) ||
    (a === 172 && b >= 16 && b <= 31) ||
    (a === 192 && b === 168)
  );
}

export async function assertPublicHttpsUrl(value: string) {
  const url = new URL(value);
  if (url.protocol !== "https:" || url.username || url.password)
    throw new Error(
      "Webhook yalnızca kimlik bilgisiz HTTPS adresine gönderilebilir.",
    );
  const host = url.hostname.toLowerCase();
  if (
    host === "localhost" ||
    host.endsWith(".local") ||
    host.endsWith(".internal")
  )
    throw new Error("Özel ağ adresi kullanılamaz.");
  const literal = isIP(host) ? [host] : [];
  const resolved = literal.length
    ? literal
    : [
        ...(await resolve4(host).catch(() => [])),
        ...(await resolve6(host).catch(() => [])),
      ];
  if (!resolved.length || resolved.some(isPrivateAddress))
    throw new Error("Webhook adresi genel internette çözümlenemedi.");
  return url;
}
