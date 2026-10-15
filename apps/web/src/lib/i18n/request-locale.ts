import { cookies } from "next/headers";
import { resolveLocale } from "./locale";

export async function getRequestLocale() {
  const cookieStore = await cookies();
  return resolveLocale(cookieStore.get("kartvizyon_locale")?.value);
}
