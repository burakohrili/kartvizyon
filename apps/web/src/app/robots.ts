import type { MetadataRoute } from "next";
export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: [
          "/",
          "/privacy",
          "/kvkk",
          "/terms",
          "/support",
          "/account-deletion",
        ],
        disallow: ["/api/", "/dashboard", "/settings", "/visits", "/customers"],
      },
    ],
    sitemap: "https://kartvizyon.app/sitemap.xml",
    host: "https://kartvizyon.app",
  };
}
