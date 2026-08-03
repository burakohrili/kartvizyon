import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "KartVizyon AI",
    short_name: "KartVizyon",
    description: "Saha müşteri hafızası ve ziyaret yönetimi",
    start_url: "/",
    display: "standalone",
    background_color: "#f7f8fc",
    theme_color: "#1b1f3b",
    lang: "tr",
    icons: [
      {
        src: "/icon.svg",
        sizes: "any",
        type: "image/svg+xml",
      },
    ],
  };
}
