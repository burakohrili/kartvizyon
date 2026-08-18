import { fileURLToPath } from "node:url";
import { defineConfig } from "vitest/config";

export default defineConfig({
  // Next.js `@/…` takma adı testlerde de çözülmeli; aksi halde App Router
  // route dosyaları hiç import edilemiyor ve uç davranışı yalnız elle
  // sınanabiliyordu.
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
  test: {
    include: ["src/**/*.test.ts"],
  },
});
