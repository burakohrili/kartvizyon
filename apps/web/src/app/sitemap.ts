import type { MetadataRoute } from "next";
const routes = [
  "",
  "/privacy",
  "/kvkk",
  "/terms",
  "/about",
  "/contact",
  "/distance-sales",
  "/delivery-refund",
  "/support",
  "/account-deletion",
];
export default function sitemap(): MetadataRoute.Sitemap {
  return routes.map((route) => ({
    url: `https://kartvizyon.app${route}`,
    lastModified: new Date("2026-08-03"),
    changeFrequency: route ? "monthly" : "weekly",
    priority: route ? 0.6 : 1,
  }));
}
