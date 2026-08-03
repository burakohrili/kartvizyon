import type { ErrorEvent, EventHint } from "@sentry/nextjs";

const sensitiveKey =
  /authorization|cookie|token|secret|password|transcript|audio|document|prompt/i;

function scrubRecord(value: Record<string, unknown> | undefined) {
  if (!value) return value;
  return Object.fromEntries(
    Object.entries(value).map(([key, item]) => [
      key,
      sensitiveKey.test(key) ? "[Filtered]" : item,
    ]),
  );
}

function scrubHeaders(value: Record<string, string> | undefined) {
  if (!value) return value;
  return Object.fromEntries(
    Object.entries(value).map(([key, item]) => [
      key,
      sensitiveKey.test(key) ? "[Filtered]" : item,
    ]),
  );
}

export function scrubSentryEvent(event: ErrorEvent, _hint: EventHint) {
  if (event.user) event.user = { id: event.user.id };
  if (event.request) {
    delete event.request.data;
    delete event.request.cookies;
    event.request.headers = scrubHeaders(event.request.headers);
  }
  event.extra = scrubRecord(event.extra);
  event.contexts = Object.fromEntries(
    Object.entries(event.contexts ?? {}).filter(
      ([key]) => !sensitiveKey.test(key),
    ),
  );
  return event;
}
