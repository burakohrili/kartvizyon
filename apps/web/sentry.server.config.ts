import * as Sentry from "@sentry/nextjs";
import { scrubSentryEvent } from "./src/lib/sentry-scrub";

const dsn = process.env.SENTRY_DSN ?? process.env.NEXT_PUBLIC_SENTRY_DSN;

Sentry.init({
  dsn,
  enabled: Boolean(dsn) && process.env.NODE_ENV === "production",
  environment: process.env.VERCEL_ENV ?? process.env.NODE_ENV,
  release: process.env.VERCEL_GIT_COMMIT_SHA,
  sendDefaultPii: false,
  includeLocalVariables: false,
  tracesSampleRate: 0.1,
  beforeSend: scrubSentryEvent,
});
