export type TabularRow = Record<string, string>;

export function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let cell = "";
  let quoted = false;
  for (let index = 0; index < text.length; index += 1) {
    const char = text[index];
    const next = text[index + 1];
    if (char === '"' && quoted && next === '"') {
      cell += '"';
      index += 1;
    } else if (char === '"') quoted = !quoted;
    else if (char === "," && !quoted) {
      row.push(cell);
      cell = "";
    } else if ((char === "\n" || char === "\r") && !quoted) {
      if (char === "\r" && next === "\n") index += 1;
      row.push(cell);
      if (row.some((value) => value.trim() !== "")) rows.push(row);
      row = [];
      cell = "";
    } else cell += char;
  }
  row.push(cell);
  if (row.some((value) => value.trim() !== "")) rows.push(row);
  return rows;
}

export function sanitizeCell(value: unknown): string {
  const text = String(value ?? "")
    .trim()
    .slice(0, 1000);
  return /^[=@]/.test(text) || /^[+-](?!\d)/.test(text) ? `'${text}` : text;
}

export function toRecords(matrix: unknown[][]): {
  headers: string[];
  rows: TabularRow[];
} {
  const rawHeaders = (matrix[0] ?? []).map(
    (value, index) => sanitizeCell(value) || `Kolon ${index + 1}`,
  );
  const seen = new Map<string, number>();
  const headers = rawHeaders.map((header) => {
    const count = seen.get(header) ?? 0;
    seen.set(header, count + 1);
    return count === 0 ? header : `${header} (${count + 1})`;
  });
  const rows = matrix
    .slice(1)
    .map((values) =>
      Object.fromEntries(
        headers.map((header, index) => [header, sanitizeCell(values[index])]),
      ),
    )
    .filter((record) => Object.values(record).some(Boolean));
  return { headers, rows };
}

const aliases: Record<string, string[]> = {
  name: [
    "firma",
    "firma adı",
    "şirket",
    "şirket adı",
    "müşteri",
    "company",
    "name",
  ],
  phone: ["telefon", "tel", "gsm", "phone", "mobile"],
  email: ["e-posta", "eposta", "email", "mail"],
  website: ["web", "web sitesi", "website", "url"],
  address: ["adres", "address", "konum"],
};

export function suggestMapping(
  headers: string[],
): Record<string, string | null> {
  return Object.fromEntries(
    Object.entries(aliases).map(([field, names]) => [
      field,
      headers.find((header) =>
        names.includes(header.toLocaleLowerCase("tr-TR").trim()),
      ) ?? null,
    ]),
  );
}
