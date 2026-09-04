import type { NextConfig } from "next";
import { withSentryConfig } from "@sentry/nextjs/config";

const nextConfig: NextConfig = {
  // Vercel supplies a Next build adapter; Next 16.3 cannot combine that adapter
  // with standalone output. Vercel does not consume the standalone bundle.
  output: process.env.VERCEL ? undefined : "standalone",
  transpilePackages: ["@kartvizyon/contracts"],
  outputFileTracingIncludes: {
    "/api/reports/export/*": ["./assets/fonts/*.woff"],
  },
  async redirects() {
    return [
      {
        source: "/favicon.png",
        destination: "/icon.svg",
        permanent: true,
      },
    ];
  },
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          {
            key: "Permissions-Policy",
            value: "camera=(self), microphone=(self), geolocation=(self)",
          },
          { key: "X-Frame-Options", value: "DENY" },
          {
            key: "Content-Security-Policy",
            value: "frame-ancestors 'none'; base-uri 'self'; object-src 'none'",
          },
        ],
      },
    ];
  },
};

export default withSentryConfig(nextConfig, {
  org: process.env.SENTRY_ORG,
  project: process.env.SENTRY_PROJECT,
  authToken: process.env.SENTRY_AUTH_TOKEN,
  silent: !process.env.CI,
  widenClientFileUpload: true,
  tunnelRoute: "/monitoring",
  sourcemaps: { deleteSourcemapsAfterUpload: true },
});
