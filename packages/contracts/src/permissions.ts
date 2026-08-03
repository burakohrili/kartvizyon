import { z } from "zod";

export const roleSchema = z.enum([
  "owner",
  "sales_director",
  "regional_manager",
  "team_lead",
  "field_sales",
  "report_viewer",
  "integration_manager",
]);

export type Role = z.infer<typeof roleSchema>;
export type Permission =
  | "workspace:manage"
  | "customer:read"
  | "customer:write"
  | "visit:approve"
  | "report:read"
  | "integration:manage";

const grants: Record<Role, readonly Permission[]> = {
  owner: [
    "workspace:manage",
    "customer:read",
    "customer:write",
    "visit:approve",
    "report:read",
    "integration:manage",
  ],
  sales_director: ["customer:read", "visit:approve", "report:read"],
  regional_manager: [
    "customer:read",
    "customer:write",
    "visit:approve",
    "report:read",
  ],
  team_lead: [
    "customer:read",
    "customer:write",
    "visit:approve",
    "report:read",
  ],
  field_sales: ["customer:read", "customer:write", "report:read"],
  report_viewer: ["report:read"],
  integration_manager: ["integration:manage"],
};

export function hasPermission(role: Role, permission: Permission): boolean {
  return grants[role].includes(permission);
}
