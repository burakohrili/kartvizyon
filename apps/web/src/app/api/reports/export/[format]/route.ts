import { readFile } from "node:fs/promises";
import { join } from "node:path";
import fontkit from "@pdf-lib/fontkit";
import { reportFiltersSchema } from "@kartvizyon/contracts";
import ExcelJS from "exceljs";
import { PDFDocument, rgb } from "pdf-lib";
import { apiError } from "@/lib/api";
import { loadApprovedReport, reportMetrics } from "@/lib/reports";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

const reportFontPaths = {
  regular: [
    join(
      process.cwd(),
      "assets",
      "fonts",
      "noto-sans-latin-ext-400-normal.woff",
    ),
    join(
      process.cwd(),
      "apps",
      "web",
      "assets",
      "fonts",
      "noto-sans-latin-ext-400-normal.woff",
    ),
  ],
  bold: [
    join(
      process.cwd(),
      "assets",
      "fonts",
      "noto-sans-latin-ext-700-normal.woff",
    ),
    join(
      process.cwd(),
      "apps",
      "web",
      "assets",
      "fonts",
      "noto-sans-latin-ext-700-normal.woff",
    ),
  ],
} as const;

async function readReportFont(candidates: readonly string[]) {
  for (const candidate of candidates) {
    try {
      return await readFile(candidate);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
    }
  }
  throw new Error("PDF yazı tipi bulunamadı.");
}

function filtersFrom(request: Request) {
  const params = new URL(request.url).searchParams;
  return reportFiltersSchema.parse({
    from: params.get("from") || undefined,
    to: params.get("to") || undefined,
    representativeId: params.get("representativeId") || undefined,
    companyId: params.get("companyId") || undefined,
  });
}

async function buildWorkbook(
  visits: Awaited<ReturnType<typeof loadApprovedReport>>["visits"],
) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "KartVizyon AI";
  workbook.created = new Date();
  const sheet = workbook.addWorksheet("Onaylı ziyaretler", {
    views: [{ state: "frozen", ySplit: 1 }],
  });
  sheet.columns = [
    { header: "Tarih", key: "date", width: 18 },
    { header: "Firma", key: "company", width: 28 },
    { header: "Temsilci", key: "representative", width: 24 },
    { header: "Sonuç", key: "outcome", width: 16 },
    { header: "Onaylı özet", key: "summary", width: 72 },
    { header: "Takip sayısı", key: "followUps", width: 16 },
  ];
  visits.forEach((visit) =>
    sheet.addRow({
      date: new Date(visit.approvedAt).toLocaleString("tr-TR"),
      company: visit.companyName,
      representative: visit.representativeName,
      outcome: visit.summary?.outcome ?? "belirtilmedi",
      summary: visit.summary?.summary ?? "",
      followUps: visit.summary?.followUps?.length ?? 0,
    }),
  );
  sheet.getRow(1).font = { bold: true, color: { argb: "FFFFFFFF" } };
  sheet.getRow(1).fill = {
    type: "pattern",
    pattern: "solid",
    fgColor: { argb: "FF12372A" },
  };
  sheet.getColumn("summary").alignment = { wrapText: true, vertical: "top" };
  sheet.autoFilter = "A1:F1";
  return new Uint8Array(await workbook.xlsx.writeBuffer());
}

async function buildPdf(
  visits: Awaited<ReturnType<typeof loadApprovedReport>>["visits"],
) {
  const [regularBytes, boldBytes] = await Promise.all([
    readReportFont(reportFontPaths.regular),
    readReportFont(reportFontPaths.bold),
  ]);
  const pdf = await PDFDocument.create();
  pdf.registerFontkit(fontkit);
  const regular = await pdf.embedFont(regularBytes);
  const bold = await pdf.embedFont(boldBytes);
  const { positive, followUps } = reportMetrics(visits);
  const pageSize: [number, number] = [595.28, 841.89];
  let page = pdf.addPage(pageSize);
  let y = 790;
  const drawHeader = () => {
    page.drawText("KartVizyon AI", {
      x: 44,
      y,
      size: 18,
      font: bold,
      color: rgb(0.07, 0.22, 0.16),
    });
    y -= 28;
    page.drawText("Onaylı saha ziyaretleri raporu", {
      x: 44,
      y,
      size: 13,
      font: bold,
    });
    y -= 24;
    page.drawText(
      `${visits.length} ziyaret  •  ${positive} olumlu sonuç  •  ${followUps} takip`,
      { x: 44, y, size: 9, font: regular, color: rgb(0.3, 0.35, 0.33) },
    );
    y -= 28;
  };
  drawHeader();

  for (const visit of visits) {
    if (y < 100) {
      page = pdf.addPage(pageSize);
      y = 790;
      drawHeader();
    }
    page.drawText(visit.companyName.slice(0, 55), {
      x: 44,
      y,
      size: 10,
      font: bold,
    });
    page.drawText(new Date(visit.approvedAt).toLocaleDateString("tr-TR"), {
      x: 470,
      y,
      size: 9,
      font: regular,
    });
    y -= 15;
    page.drawText(visit.representativeName.slice(0, 60), {
      x: 44,
      y,
      size: 8,
      font: regular,
      color: rgb(0.35, 0.4, 0.38),
    });
    y -= 14;
    const summary = (visit.summary?.summary ?? "Özet bulunmuyor").replace(
      /\s+/g,
      " ",
    );
    const lines = summary.match(/.{1,92}(?:\s|$)/g)?.slice(0, 3) ?? [summary];
    for (const line of lines) {
      page.drawText(line.trim(), { x: 44, y, size: 8.5, font: regular });
      y -= 12;
    }
    y -= 12;
    page.drawLine({
      start: { x: 44, y },
      end: { x: 550, y },
      thickness: 0.5,
      color: rgb(0.85, 0.87, 0.86),
    });
    y -= 16;
  }
  return pdf.save();
}

export async function GET(
  request: Request,
  { params }: { params: Promise<{ format: string }> },
) {
  try {
    const { format } = await params;
    if (format !== "pdf" && format !== "xlsx") {
      return Response.json(
        { error: "Desteklenmeyen rapor biçimi." },
        { status: 404 },
      );
    }
    const filters = filtersFrom(request);
    const report = await loadApprovedReport(filters, request);
    const data =
      format === "xlsx"
        ? await buildWorkbook(report.visits)
        : await buildPdf(report.visits);

    if (report.authenticated && report.workspaceId) {
      const supabase = await createSupabaseServerClient(request);
      await supabase?.rpc("record_report_export", {
        target_workspace_id: report.workspaceId,
        export_format: format,
        report_filters: filters,
      });
    }

    const body = data.buffer.slice(
      data.byteOffset,
      data.byteOffset + data.byteLength,
    ) as ArrayBuffer;
    return new Response(body, {
      headers: {
        "Content-Type":
          format === "xlsx"
            ? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            : "application/pdf",
        "Content-Disposition": `attachment; filename="kartvizyon-rapor.${format}"`,
        "Cache-Control": "private, no-store",
      },
    });
  } catch (error) {
    if (process.env.NODE_ENV === "development" && error instanceof Error) {
      console.error(error);
      return Response.json(
        { error: "Rapor üretilemedi.", detail: error.message },
        { status: 500 },
      );
    }
    return apiError(error);
  }
}
