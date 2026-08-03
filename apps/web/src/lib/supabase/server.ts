import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { getSupabaseConfig } from "./config";

export async function createSupabaseServerClient(request?: Request) {
  const config = getSupabaseConfig();
  if (!config) return null;
  const cookieStore = await cookies();

  const authorization = request?.headers.get("authorization");
  return createServerClient(config.url, config.anonKey, {
    global: authorization
      ? { headers: { Authorization: authorization } }
      : undefined,
    cookies: {
      getAll: () => cookieStore.getAll(),
      setAll: (cookiesToSet) => {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options),
          );
        } catch {
          // Server Components cannot always write cookies; proxy refreshes sessions.
        }
      },
    },
  });
}
