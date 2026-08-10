import { NextRequest, NextResponse } from "next/server";

import { createSupabaseServerClient } from "@/lib/supabase/server";

function safeNext(value: string | null) {
  return value?.startsWith("/") && !value.startsWith("//")
    ? value
    : "/dashboard";
}

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  const next = safeNext(request.nextUrl.searchParams.get("next"));
  const destination = new URL(next, request.url);
  const supabase = await createSupabaseServerClient();

  if (!code || !supabase) {
    destination.pathname = "/login";
    destination.search = "?error=verification";
    return NextResponse.redirect(destination);
  }

  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) {
    destination.pathname = "/login";
    destination.search = "?error=verification";
  }

  return NextResponse.redirect(destination);
}
