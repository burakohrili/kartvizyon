import { createHash, randomUUID } from "node:crypto";
import ExcelJS from "exceljs";
import { companyCreateSchema } from "@kartvizyon/contracts";
import { apiError, serviceUnavailable } from "@/lib/api";
import {
  parseCsv,
  sanitizeCell,
  suggestMapping,
  toRecords,
  type TabularRow,
} from "@/lib/import/parse";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const runtime = "nodejs";
const MAX_FILE_SIZE = 10 * 1024 * 1024;
const MAX_ROWS = 10_000;
const allowedExtensions = [".csv", ".xlsx"];

async function parseFile(file: File) {
  const extension = allowedExtensions.find((item) =>
    file.name.toLocaleLowerCase("tr-TR").endsWith(item),
  );
  if (!extension)
    throw new Error("Yalnızca CSV ve XLSX dosyaları desteklenir.");
  if (file.size === 0 || file.size > MAX_FILE_SIZE)
    throw new Error("Dosya 10 MB sınırını aşıyor veya boş.");
  const bytes = Buffer.from(await file.arrayBuffer());
  let matrix: unknown[][];
  if (extension === ".xlsx") {
    if (bytes[0] !== 0x50 || bytes[1] !== 0x4b)
      throw new Error("XLSX dosya imzası geçersiz.");
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(
      bytes as unknown as Parameters<typeof workbook.xlsx.load>[0],
    );
    const sheet = workbook.worksheets[0];
    if (!sheet) throw new Error("Çalışma sayfası bulunamadı.");
    matrix = [];
    sheet.eachRow({ includeEmpty: false }, (row) => {
      const values = Array.isArray(row.values)
        ? row.values
            .slice(1)
            .map((value) =>
              typeof value === "object" && value !== null && "text" in value
                ? String(value.text)
                : value,
            )
        : [];
      matrix.push(values);
    });
  } else {
    const text = bytes.toString("utf8").replace(/^\uFEFF/, "");
    matrix = parseCsv(text);
  }
  const parsed = toRecords(matrix.slice(0, MAX_ROWS + 1));
  if (parsed.headers.length === 0 || parsed.rows.length === 0)
    throw new Error("Dosyada içe aktarılabilir satır bulunamadı.");
  return { ...parsed, hash: createHash("sha256").update(bytes).digest("hex") };
}

function buildCompany(
  row: TabularRow,
  mapping: Record<string, string | null>,
  workspaceId: string,
  organizationId: string | null,
) {
  return companyCreateSchema.safeParse({
    workspaceId,
    organizationId,
    name: mapping.name ? row[mapping.name] : "",
    phone: mapping.phone ? row[mapping.phone] : undefined,
    email: mapping.email ? row[mapping.email] : undefined,
    website: mapping.website ? row[mapping.website] : undefined,
    address: mapping.address ? row[mapping.address] : undefined,
    clientMutationId: randomUUID(),
  });
}

export async function POST(request: Request) {
  try {
    const form = await request.formData();
    const file = form.get("file");
    if (!(file instanceof File))
      return Response.json({ error: "Dosya gerekli." }, { status: 400 });
    const parsed = await parseFile(file);
    const action = String(form.get("action") ?? "preview");
    if (action === "preview") {
      return Response.json({
        data: {
          headers: parsed.headers,
          previewRows: parsed.rows.slice(0, 20),
          totalRows: parsed.rows.length,
          suggestedMapping: suggestMapping(parsed.headers),
          fileHash: parsed.hash,
        },
      });
    }

    const workspaceId = String(form.get("workspaceId") ?? "");
    const organizationIdValue = String(form.get("organizationId") ?? "");
    const organizationId = organizationIdValue || null;
    const mapping = JSON.parse(String(form.get("mapping") ?? "{}")) as Record<
      string,
      string | null
    >;
    if (!mapping.name)
      return Response.json(
        { error: "Firma adı kolonu zorunludur." },
        { status: 400 },
      );
    const valid: Array<Record<string, unknown>> = [];
    const errors: Array<{ row: number; reason: string }> = [];
    parsed.rows.forEach((row, index) => {
      const result = buildCompany(row, mapping, workspaceId, organizationId);
      if (!result.success)
        errors.push({
          row: index + 2,
          reason: result.error.issues[0]?.message ?? "Geçersiz satır",
        });
      else
        valid.push({
          workspace_id: result.data.workspaceId,
          organization_id: result.data.organizationId,
          name: sanitizeCell(result.data.name),
          phone: result.data.phone,
          email: result.data.email,
          website: result.data.website,
          address: result.data.address,
          client_mutation_id: result.data.clientMutationId,
        });
    });

    const supabase = await createSupabaseServerClient();
    if (!supabase)
      return Response.json({
        data: {
          simulated: true,
          totalRows: parsed.rows.length,
          importableRows: valid.length,
          skippedRows: errors.length,
          errors: errors.slice(0, 100),
        },
      });
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });
    if (!workspaceId)
      return Response.json(
        { error: "Çalışma alanı gerekli." },
        { status: 400 },
      );
    const { data: job, error: jobError } = await supabase
      .from("import_jobs")
      .insert({
        workspace_id: workspaceId,
        organization_id: organizationId,
        created_by: user.id,
        file_name: file.name,
        file_hash: parsed.hash,
        file_size: file.size,
        status: "processing",
        column_mapping: mapping,
        total_rows: parsed.rows.length,
      })
      .select("id")
      .single();
    if (jobError) return apiError(jobError);
    const createdIds: string[] = [];
    for (let index = 0; index < valid.length; index += 500) {
      const batch = valid
        .slice(index, index + 500)
        .map((company) => ({ ...company, created_by: user.id }));
      const { data, error } = await supabase
        .from("companies")
        .insert(batch)
        .select("id");
      if (error) {
        errors.push({ row: index + 2, reason: error.message });
        break;
      }
      createdIds.push(...(data ?? []).map((item) => item.id));
    }
    await supabase
      .from("import_jobs")
      .update({
        status:
          errors.length > 0 && createdIds.length === 0 ? "failed" : "completed",
        imported_rows: createdIds.length,
        skipped_rows: parsed.rows.length - createdIds.length,
        error_rows: errors.slice(0, 500),
        created_company_ids: createdIds,
        completed_at: new Date().toISOString(),
      })
      .eq("id", job.id);
    return Response.json(
      {
        data: {
          jobId: job.id,
          totalRows: parsed.rows.length,
          importedRows: createdIds.length,
          skippedRows: parsed.rows.length - createdIds.length,
          errors: errors.slice(0, 100),
        },
      },
      { status: 201 },
    );
  } catch (error) {
    if (
      error instanceof Error &&
      /dosya|satır|çalışma sayfası/i.test(error.message)
    )
      return Response.json({ error: error.message }, { status: 400 });
    return apiError(error);
  }
}
