import { createHash, randomBytes } from "node:crypto";
import {
  apiCredentialCreateSchema,
  webhookCreateSchema,
} from "@kartvizyon/contracts";
import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";
import { encryptSecret } from "@/lib/secret-box";

const requestSchema = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("api_credential"),
    data: apiCredentialCreateSchema,
  }),
  z.object({ kind: z.literal("webhook"), data: webhookCreateSchema }),
]);

const revokeSchema = z.object({
  kind: z.enum(["api_credential", "webhook"]),
  id: z.uuid(),
});

const digest = (value: string) =>
  createHash("sha256").update(value).digest("hex");

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const [credentials, webhooks] = await Promise.all([
      context.supabase
        .from("api_credentials")
        .select(
          "id,name,token_prefix,scopes,last_used_at,expires_at,revoked_at,created_at",
        )
        .eq("workspace_id", context.workspaceId)
        .order("created_at", { ascending: false }),
      context.supabase
        .from("webhook_endpoints")
        .select("id,name,url,events,signing_secret_prefix,active,created_at")
        .eq("workspace_id", context.workspaceId)
        .order("created_at", { ascending: false }),
    ]);
    if (credentials.error) throw credentials.error;
    if (webhooks.error) throw webhooks.error;
    return Response.json({
      credentials: credentials.data,
      webhooks: webhooks.data,
    });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = requestSchema.parse(await request.json());
    if (input.data.workspaceId !== context.workspaceId)
      return Response.json(
        { error: "Çalışma alanı uyuşmuyor." },
        { status: 403 },
      );

    if (input.kind === "api_credential") {
      const secret = `kv_${randomBytes(32).toString("base64url")}`;
      const { data, error } = await context.supabase
        .from("api_credentials")
        .insert({
          workspace_id: context.workspaceId,
          organization_id: context.organizationId,
          name: input.data.name,
          token_prefix: secret.slice(0, 11),
          token_hash: digest(secret),
          scopes: input.data.scopes,
          created_by: context.user.id,
        })
        .select("id,name,token_prefix,scopes,created_at")
        .single();
      if (error) throw error;
      return Response.json({ data, secret }, { status: 201 });
    }

    if (!process.env.INTEGRATION_ENCRYPTION_KEY) {
      return Response.json(
        { error: "Webhook şifreleme anahtarı yapılandırılmadı." },
        { status: 503 },
      );
    }
    const secret = `whsec_${randomBytes(32).toString("base64url")}`;
    const { data, error } = await context.supabase
      .from("webhook_endpoints")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        name: input.data.name,
        url: input.data.url,
        events: input.data.events,
        signing_secret_hash: digest(secret),
        signing_secret_prefix: secret.slice(0, 13),
        signing_secret_ciphertext: encryptSecret(secret),
        created_by: context.user.id,
      })
      .select("id,name,url,events,signing_secret_prefix,active,created_at")
      .single();
    if (error) throw error;
    return Response.json({ data, secret }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}

export async function DELETE(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = revokeSchema.parse(await request.json());
    const table =
      input.kind === "api_credential" ? "api_credentials" : "webhook_endpoints";
    const update =
      input.kind === "api_credential"
        ? { revoked_at: new Date().toISOString() }
        : { active: false, updated_at: new Date().toISOString() };
    const { error } = await context.supabase
      .from(table)
      .update(update)
      .eq("id", input.id)
      .eq("workspace_id", context.workspaceId);
    if (error) throw error;
    await context.supabase.from("audit_logs").insert({
      organization_id: context.organizationId,
      workspace_id: context.workspaceId,
      actor_id: context.user.id,
      action: `integration.${input.kind}_revoked`,
      resource_type: input.kind,
      resource_id: input.id,
    });
    return Response.json({ ok: true });
  } catch (error) {
    return apiError(error);
  }
}
