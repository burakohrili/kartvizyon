import { timingSafeEqual } from "node:crypto";

export function hasInternalSecret(request: Request, variable: string) {
  const expected = process.env[variable];
  const received = request.headers
    .get("authorization")
    ?.replace(/^Bearer\s+/i, "");
  if (!expected || !received) return false;
  const left = Buffer.from(expected);
  const right = Buffer.from(received);
  return left.length === right.length && timingSafeEqual(left, right);
}
