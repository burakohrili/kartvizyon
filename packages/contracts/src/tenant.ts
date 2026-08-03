export type TenantContext = {
  userId: string;
  organizationId: string | null;
  workspaceId: string;
};

export function requireOrganization(context: TenantContext): string {
  if (!context.organizationId) {
    throw new Error("Kurumsal işlem için organizasyon bağlamı zorunludur.");
  }
  return context.organizationId;
}

export function assertSameOrganization(
  context: TenantContext,
  resourceOrganizationId: string,
): void {
  const organizationId = requireOrganization(context);
  if (organizationId !== resourceOrganizationId) {
    throw new Error("Bu kaynağa erişim yetkiniz yok.");
  }
}
