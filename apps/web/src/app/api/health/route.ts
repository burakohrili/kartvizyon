import { getSupabaseConfig } from "@/lib/supabase/config";

export function GET() {
  return Response.json({
    status: "ok",
    service: "kartvizyon-web",
    version: process.env.npm_package_version ?? "0.1.0",
    uptimeSeconds: Math.round(process.uptime()),
    databaseConfigured: getSupabaseConfig() !== null,
    aiConfigured: Boolean(process.env.OPENAI_API_KEY),
    adminConfigured: Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),
    timestamp: new Date().toISOString(),
  });
}
