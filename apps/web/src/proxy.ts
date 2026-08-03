import { randomUUID } from "node:crypto";
import { NextRequest, NextResponse } from "next/server";

export function proxy(request: NextRequest) {
  const startedAt = performance.now();
  const requestId = request.headers.get("x-request-id") ?? randomUUID();
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-request-id", requestId);
  const hostname = request.headers.get("host")?.split(":")[0];
  const isAppDomain = hostname === "app.kartvizyon.app";
  const response =
    isAppDomain && request.nextUrl.pathname === "/"
      ? NextResponse.rewrite(new URL("/dashboard", request.url), {
          request: { headers: requestHeaders },
        })
      : NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set("x-request-id", requestId);
  response.headers.set(
    "server-timing",
    `proxy;dur=${(performance.now() - startedAt).toFixed(2)}`,
  );
  if (request.nextUrl.pathname.startsWith("/api/")) {
    console.info(
      JSON.stringify({
        level: "info",
        event: "http.request",
        requestId,
        method: request.method,
        path: request.nextUrl.pathname,
        timestamp: new Date().toISOString(),
      }),
    );
  }
  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
