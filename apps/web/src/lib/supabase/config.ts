export type SupabaseConfig = { url: string; anonKey: string };

export function getSupabaseConfig(): SupabaseConfig | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (
    !url ||
    !anonKey ||
    url.includes("your-project") ||
    anonKey.startsWith("replace-")
  )
    return null;
  return { url, anonKey };
}
