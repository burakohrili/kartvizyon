import { invitationSchema } from "@kartvizyon/contracts";
import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const organizationId = new URL(request.url).searchParams.get(
    "organizationId",
  );
  if (!organizationId)
    return Response.json({ error: "organizationId gerekli." }, { status: 400 });
  const supabase = await createSupabaseServerClient();
  if (!supabase) return Response.json({ data: [], demo: true });
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return Response.json({ error: "Oturum gerekli." }, { status: 401 });
  const { data, error } = await supabase
    .from("invitations")
    .select("id,email,role,status,expires_at,created_at")
    .eq("organization_id", organizationId)
    .order("created_at", { ascending: false });
  if (error) return apiError(error);
  return Response.json({ data });
}

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as {
      organizationId?: string;
      email?: string;
      role?: string;
      expiresAt?: string;
    };
    const input = invitationSchema.parse({
      email: body.email,
      role: body.role,
      expiresAt: body.expiresAt,
    });
    if (!body.organizationId)
      return Response.json({ error: "Organizasyon gerekli." }, { status: 400 });
    const supabase = await createSupabaseServerClient();
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });
    const validForDays = Math.max(
      1,
      Math.min(
        30,
        Math.ceil(
          (new Date(input.expiresAt).getTime() - Date.now()) / 86_400_000,
        ),
      ),
    );
    const { data, error } = await supabase.rpc("create_invitation", {
      target_organization_id: body.organizationId,
      target_email: input.email,
      target_role: input.role,
      valid_for_days: validForDays,
    });
    if (error) return apiError(error);
    const result = Array.isArray(data) ? data[0] : data;
    const baseUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";
    return Response.json(
      {
        data: {
          id: result.invitation_id,
          inviteUrl: `${baseUrl}/invite/${result.invitation_token}`,
          delivered: false,
        },
      },
      { status: 201 },
    );
  } catch (error) {
    return apiError(error);
  }
}
