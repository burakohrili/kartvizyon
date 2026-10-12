export function validateMobileSandbox(env) {
  const required = [
    "KARTVIZYON_SANDBOX_API_URL",
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "REVENUECAT_APPLE_PUBLIC_API_KEY",
  ];
  for (const name of required) {
    if (!env[name] || env[name].includes("[SENSITIVE]")) {
      throw new Error(`Missing real Sandbox configuration: ${name}`);
    }
  }
  const api = new URL(env.KARTVIZYON_SANDBOX_API_URL);
  if (
    api.protocol !== "https:" ||
    api.username ||
    api.password ||
    api.search ||
    api.hash ||
    (api.pathname !== "/" && api.pathname !== "") ||
    api.host === "kartvizyon.app" ||
    api.host.endsWith(".kartvizyon.app")
  ) {
    throw new Error(
      "Sandbox API must be an isolated HTTPS origin, not production.",
    );
  }
  if (env.SUPABASE_URL !== "https://rfzmdpxnfsvatukkedrg.supabase.co") {
    throw new Error(
      "Sandbox builds must use the verified staging Supabase project.",
    );
  }
}

// Importable for tests; CLI does not print credentials.
if (
  process.argv[1] &&
  import.meta.url ===
    (await import("node:url")).pathToFileURL(process.argv[1]).href
) {
  try {
    validateMobileSandbox(process.env);
    console.log("Sandbox runtime isolation verified.");
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
