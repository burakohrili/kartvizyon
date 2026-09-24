import { createHmac, timingSafeEqual } from "node:crypto";
import { z } from "zod";

const optionalRevenueCatString = z.string().min(1).nullish();

export const revenueCatWebhookSchema = z.object({
  api_version: z.string(),
  event: z.object({
    id: z.string().min(1),
    type: z.string().min(1),
    event_timestamp_ms: z.number().int().nonnegative(),
    // RevenueCat may send an anonymous identifier here; UUID candidates are
    // selected only after aliases/original_app_user_id are considered.
    app_user_id: z.string().min(1).optional(),
    original_app_user_id: z.string().min(1).optional(),
    aliases: z.array(z.string().min(1)).optional(),
    transferred_from: z.array(z.string().min(1)).optional(),
    transferred_to: z.array(z.string().min(1)).optional(),
    product_id: optionalRevenueCatString,
    store: z.string().optional(),
    environment: z.enum(["PRODUCTION", "SANDBOX"]).optional(),
    // RevenueCat's dashboard TEST event sends these as null. Real purchase
    // events are still rejected below when the normalized values are absent.
    transaction_id: optionalRevenueCatString,
    original_transaction_id: optionalRevenueCatString,
    purchased_at_ms: z.number().int().nonnegative().nullable().optional(),
    expiration_at_ms: z.number().int().nonnegative().nullable().optional(),
    grace_period_expiration_at_ms: z
      .number()
      .int()
      .nonnegative()
      .nullable()
      .optional(),
  }),
});

export type RevenueCatEvent = z.infer<typeof revenueCatWebhookSchema>["event"];

export function revenueCatUserIds(event: RevenueCatEvent) {
  return [
    event.app_user_id,
    event.original_app_user_id,
    ...(event.aliases ?? []),
  ]
    .filter((value): value is string =>
      Boolean(value && z.uuid().safeParse(value).success),
    )
    .filter((value, index, values) => values.indexOf(value) === index);
}

export function revenueCatUuidIds(values?: string[]) {
  return (values ?? [])
    .filter((value) => z.uuid().safeParse(value).success)
    .filter((value, index, all) => all.indexOf(value) === index);
}

export function secureHeaderEquals(actual: string | null, expected: string) {
  if (!actual || !expected) return false;
  const left = Buffer.from(actual);
  const right = Buffer.from(expected);
  return left.length === right.length && timingSafeEqual(left, right);
}

export function verifyRevenueCatSignature(
  rawBody: string,
  header: string | null,
  secret: string,
  nowSeconds = Math.floor(Date.now() / 1000),
) {
  if (!header || !secret) return false;
  const values = Object.fromEntries(
    header.split(",").map((part) => {
      const [key, ...rest] = part.trim().split("=");
      return [key, rest.join("=")];
    }),
  );
  const timestamp = Number(values.t);
  const supplied = values.v1;
  if (!Number.isInteger(timestamp) || Math.abs(nowSeconds - timestamp) > 300)
    return false;
  const expected = createHmac("sha256", secret)
    .update(`${timestamp}.${rawBody}`)
    .digest("hex");
  return secureHeaderEquals(supplied ?? null, expected);
}

export function normalizeStore(store?: string) {
  if (store === "APP_STORE" || store === "MAC_APP_STORE") return "apple";
  if (store === "PLAY_STORE") return "google";
  return null;
}

export function splitStoreProduct(productId: string, provider: string) {
  if (provider !== "google") return { productId, basePlanId: null };
  const separator = productId.indexOf(":");
  return separator < 0
    ? { productId, basePlanId: null }
    : {
        productId: productId.slice(0, separator),
        basePlanId: productId.slice(separator + 1),
      };
}

export function lifecycleFor(event: RevenueCatEvent) {
  switch (event.type) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "PRODUCT_CHANGE":
    case "UNCANCELLATION":
    case "SUBSCRIPTION_EXTENDED":
    case "REFUND_REVERSED":
      return { status: "active" as const, autoRenewing: true };
    case "CANCELLATION":
      return { status: "cancelled" as const, autoRenewing: false };
    case "SUBSCRIPTION_PAUSED":
      return { status: "cancelled" as const, autoRenewing: false };
    case "BILLING_ISSUE":
      return { status: "past_due" as const, autoRenewing: false };
    case "EXPIRATION":
      return { status: "cancelled" as const, autoRenewing: false };
    default:
      return null;
  }
}

export function dateFromMs(value?: number | null) {
  return value == null ? null : new Date(value).toISOString();
}
