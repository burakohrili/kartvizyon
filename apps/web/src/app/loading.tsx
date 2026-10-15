import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export default async function Loading() {
  const messages = getMessages(await getRequestLocale()).errorPage;
  return <main style={{ padding: 48 }}>{messages.loading}</main>;
}
