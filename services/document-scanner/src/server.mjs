import { createHash, timingSafeEqual } from "node:crypto";
import { createWriteStream } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pipeline } from "node:stream/promises";
import { Readable } from "node:stream";
import { spawn } from "node:child_process";
import { pathToFileURL } from "node:url";

const port = Number(process.env.PORT || 8080);

export function authorized(request, secret = process.env.DOCUMENT_SCAN_SECRET) {
  const received = request.headers.authorization?.replace(/^Bearer\s+/i, "");
  if (!secret || !received) return false;
  const left = Buffer.from(secret);
  const right = Buffer.from(received);
  return left.length === right.length && timingSafeEqual(left, right);
}

async function readJson(request) {
  const chunks = [];
  let bytes = 0;
  for await (const chunk of request) {
    bytes += chunk.length;
    if (bytes > 32 * 1024) throw new Error("İstek gövdesi çok büyük");
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}");
}

export function configuredAppUrl(raw = process.env.APP_BASE_URL) {
  if (!raw) throw new Error("APP_BASE_URL tanımlı değil");
  const url = new URL(raw);
  if (url.protocol !== "https:" && url.hostname !== "localhost")
    throw new Error("APP_BASE_URL HTTPS olmalı");
  return url;
}

function runClamScan(path) {
  return new Promise((resolve, reject) => {
    const child = spawn("clamscan", ["--no-summary", "--infected", path], {
      stdio: ["ignore", "pipe", "pipe"],
    });
    let output = "";
    child.stdout.on("data", (chunk) => (output += chunk));
    child.stderr.on("data", (chunk) => (output += chunk));
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) resolve({ status: "clean", signature: "ClamAV:clean" });
      else if (code === 1)
        resolve({
          status: "blocked",
          signature:
            output.split(" FOUND")[0].split(": ").pop()?.trim() ||
            "ClamAV:infected",
        });
      else reject(new Error(output.trim() || `clamscan exited with ${code}`));
    });
  });
}

async function callback(appUrl, job, result) {
  const response = await fetch(
    new URL("/api/internal/documents/scan-result", appUrl),
    {
      method: "POST",
      headers: {
        authorization: `Bearer ${process.env.DOCUMENT_SCAN_SECRET}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        documentId: job.documentId,
        sha256: job.sha256,
        status: result.status,
        scannerSignature: result.signature,
        error: result.error,
      }),
    },
  );
  if (!response.ok) throw new Error(`Callback HTTP ${response.status}`);
}

async function scanJob(appUrl, job) {
  const directory = await mkdtemp(join(tmpdir(), "kartvizyon-scan-"));
  const path = join(directory, "upload.bin");
  try {
    const download = await fetch(job.downloadUrl, { redirect: "error" });
    if (!download.ok || !download.body)
      throw new Error(`Download HTTP ${download.status}`);
    const advertisedLength = Number(
      download.headers.get("content-length") || 0,
    );
    if (advertisedLength > 20 * 1024 * 1024)
      throw new Error("Dosya boyutu sınırı aşıldı");
    const hash = createHash("sha256");
    let bytes = 0;
    const body = Readable.fromWeb(download.body);
    body.on("data", (chunk) => {
      bytes += chunk.length;
      if (bytes > 20 * 1024 * 1024)
        body.destroy(new Error("Dosya boyutu sınırı aşıldı"));
      hash.update(chunk);
    });
    await pipeline(body, createWriteStream(path, { flags: "wx", mode: 0o600 }));
    if (hash.digest("hex") !== job.sha256)
      throw new Error("SHA-256 özeti uyuşmuyor");
    const result = await runClamScan(path);
    await callback(appUrl, job, result);
    return result.status;
  } catch (error) {
    await callback(appUrl, job, {
      status: "failed",
      signature: "ClamAV:error",
      error:
        error instanceof Error ? error.message.slice(0, 500) : "Tarama hatası",
    });
    return "failed";
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

export function createAppServer() {
  return createServer(async (request, response) => {
    if (request.url === "/health" && request.method === "GET") {
      try {
        const engine = await new Promise((resolve, reject) => {
          const child = spawn("clamscan", ["--version"], {
            stdio: ["ignore", "pipe", "pipe"],
          });
          let output = "";
          child.stdout.on("data", (chunk) => (output += chunk));
          child.stderr.on("data", (chunk) => (output += chunk));
          child.on("error", reject);
          child.on("close", (code) =>
            code === 0
              ? resolve(output.trim())
              : reject(new Error(output.trim())),
          );
        });
        configuredAppUrl();
        if (!process.env.DOCUMENT_SCAN_SECRET)
          throw new Error("DOCUMENT_SCAN_SECRET tanımlı değil");
        response.writeHead(200, { "content-type": "application/json" });
        return response.end(JSON.stringify({ ok: true, engine }));
      } catch {
        response.writeHead(503, { "content-type": "application/json" });
        return response.end(JSON.stringify({ ok: false }));
      }
    }
    if (request.url !== "/scan" || request.method !== "POST") {
      response.writeHead(404).end();
      return;
    }
    if (!authorized(request)) {
      response.writeHead(401, { "content-type": "application/json" });
      return response.end(JSON.stringify({ error: "Yetkisiz." }));
    }
    try {
      const input = await readJson(request);
      const appUrl = configuredAppUrl();
      const jobsResponse = await fetch(
        new URL("/api/internal/documents/scan-jobs", appUrl),
        {
          method: "POST",
          headers: {
            authorization: `Bearer ${process.env.DOCUMENT_SCAN_SECRET}`,
            "content-type": "application/json",
          },
          body: JSON.stringify({
            limit: Math.min(Math.max(Number(input.limit) || 5, 1), 20),
          }),
        },
      );
      if (!jobsResponse.ok)
        throw new Error(`İş kuyruğu HTTP ${jobsResponse.status}`);
      const { jobs = [] } = await jobsResponse.json();
      const results = { clean: 0, blocked: 0, failed: 0 };
      for (const job of jobs) results[await scanJob(appUrl, job)] += 1;
      response.writeHead(200, { "content-type": "application/json" });
      response.end(JSON.stringify({ processed: jobs.length, ...results }));
    } catch (error) {
      response.writeHead(500, { "content-type": "application/json" });
      response.end(
        JSON.stringify({
          error: error instanceof Error ? error.message : "Tarama hatası",
        }),
      );
    }
  });
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  configuredAppUrl();
  if (!process.env.DOCUMENT_SCAN_SECRET)
    throw new Error("DOCUMENT_SCAN_SECRET tanımlı değil");
  createAppServer().listen(port, () => {
    console.log(
      JSON.stringify({ level: "info", event: "scanner.ready", port }),
    );
  });
}
