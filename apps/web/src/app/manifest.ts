import type { MetadataRoute } from "next";
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "KartVizyon AI",
    short_name: "KartVizyon",
    description:
      "Saha satış ekipleri için yapay zekâ destekli müşteri hafızası",
    start_url: "/",
    display: "standalone",
    background_color: "#f4f0e8",
    theme_color: "#101c3d",
    lang: "tr",
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
  };
}
