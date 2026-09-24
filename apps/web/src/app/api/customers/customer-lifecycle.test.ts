import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";

const customerDetailRoute = readFileSync(
  new URL("./[id]/route.ts", import.meta.url),
  "utf8",
);
const contactsRoute = readFileSync(
  new URL("../contacts/route.ts", import.meta.url),
  "utf8",
);

describe("customer lifecycle tenant boundaries", () => {
  it("scopes company update and archive to the canonical workspace", () => {
    expect(customerDetailRoute).toContain("getApiContext(request)");
    expect(customerDetailRoute).toContain(
      '.eq("workspace_id", context.workspaceId)',
    );
    expect(customerDetailRoute).toContain("archived_at");
    expect(customerDetailRoute).not.toContain(".delete()");
  });

  it("does not trust contact workspace fields from the request body", () => {
    expect(contactsRoute).toContain("getApiContext(request)");
    expect(contactsRoute).toContain("workspace_id: context.workspaceId");
    expect(contactsRoute).toContain("organization_id: context.organizationId");
    expect(contactsRoute).toContain('.eq("workspace_id", context.workspaceId)');
  });
});
