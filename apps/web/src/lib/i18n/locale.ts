export type AppLocale = "tr" | "en";

export function resolveLocale(value: string | null | undefined): AppLocale {
  return value?.trim().toLowerCase().startsWith("en") ? "en" : "tr";
}

export function intlLocale(locale: AppLocale): string {
  return locale === "en" ? "en-US" : "tr-TR";
}

export function formatDate(
  value: Date | string | number,
  locale: AppLocale,
  options: Intl.DateTimeFormatOptions = { dateStyle: "medium" },
): string {
  return new Intl.DateTimeFormat(intlLocale(locale), options).format(
    value instanceof Date ? value : new Date(value),
  );
}

export function formatDateTime(
  value: Date | string | number,
  locale: AppLocale,
  options: Intl.DateTimeFormatOptions = {
    dateStyle: "medium",
    timeStyle: "short",
  },
): string {
  return new Intl.DateTimeFormat(intlLocale(locale), options).format(
    value instanceof Date ? value : new Date(value),
  );
}

export function formatNumber(value: number, locale: AppLocale): string {
  return new Intl.NumberFormat(intlLocale(locale)).format(value);
}

export function formatCurrency(
  value: number,
  currency: string,
  locale: AppLocale,
): string {
  return new Intl.NumberFormat(intlLocale(locale), {
    style: "currency",
    currency,
  }).format(value);
}
