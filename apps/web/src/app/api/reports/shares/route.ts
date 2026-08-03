import { randomBytes } from "node:crypto";
import {
  reportShareCreateSchema,
  reportShareRevokeSchema,
} from "@kartvizyon/contracts";
import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  try {
    const supabase = await createSupabaseServerClient(request);
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });

    const input = reportShareCreateSchema.parse(await request.json());
    const token = randomBytes(32).toString("hex");
    const { data, error } = await supabase.rpc("create_report_share", {
      target_workspace_id: input.workspaceId,
      raw_token: token,
      report_title: input.title,
      report_filters: input.filters,
      valid_for_hours: input.validForHours,
    });
    if (error) throw error;
    return Response.json(
      {
        id: data,
        url: `${new URL(request.url).origin}/share/reports/${token}`,
      },
      { status: 201 },
    );
  } catch (error) {
    return apiError(error);
  }
}

export async function DELETE(request: Request) {
  try {
    const supabase = await createSupabaseServerClient(request);
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });
    const { shareId } = reportShareRevokeSchema.parse(await request.json());
    const { data, error } = await supabase.rpc("revoke_report_share", {
      target_share_id: shareId,
    });
    if (error) throw error;
    if (!data)
      return Response.json({ error: "Paylaşım bulunamadı." }, { status: 404 });
    return Response.json({ revoked: true });
  } catch (error) {
    return apiError(error);
  }
}
