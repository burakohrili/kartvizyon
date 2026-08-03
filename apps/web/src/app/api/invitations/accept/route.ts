import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  const { token } = (await request.json()) as { token?: string };
  if (!token || !/^[a-f0-9]{64}$/i.test(token))
    return Response.json({ error: "Davet tokenı geçersiz." }, { status: 400 });
  const supabase = await createSupabaseServerClient();
  if (!supabase) return serviceUnavailable();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return Response.json(
      { error: "Daveti kabul etmek için giriş yapın." },
      { status: 401 },
    );
  const { data, error } = await supabase.rpc("accept_invitation", {
    invitation_token: token,
  });
  if (error) return apiError(error);
  return Response.json({ data: { organizationId: data } });
}
