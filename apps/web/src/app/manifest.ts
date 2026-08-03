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
  };
}
