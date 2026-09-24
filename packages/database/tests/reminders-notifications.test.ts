import { readFile } from "node:fs/promises";
import { describe, expect, it } from "vitest";

const up = await readFile(
  new URL("../migrations/0029_reminders_notifications.up.sql", import.meta.url),
  "utf8",
);
const down = await readFile(
  new URL(
    "../migrations/0029_reminders_notifications.down.sql",
    import.meta.url,
  ),
  "utf8",
);

describe("reminder notification migration", () => {
  it("has database-enforced semantic idempotency", () => {
    expect(up).toContain("notifications_user_occurrence_key_idx");
    expect(up).toContain("on conflict (user_id, occurrence_key)");
    expect(up.match(/on conflict \(user_id, occurrence_key\)/g)).toHaveLength(
      5,
    );
  });

  it("keeps domain notification creation away from authenticated clients", () => {
    expect(up).toContain("drop policy notifications_owner_all");
    expect(up).not.toMatch(/notifications_owner_insert/);
    expect(up).toContain(
      "revoke all on function public.process_reminders(timestamptz, integer) from public, anon, authenticated",
    );
  });

  it("explicitly exposes only preference operations needed by the Data API", () => {
    expect(up).toContain(
      "grant select, insert, update on public.notification_preferences to authenticated",
    );
    expect(up).toContain(
      "revoke all on public.notification_preferences from anon, authenticated",
    );
    expect(up).not.toContain("auth.role()");
  });

  it("targets only owners and assignees and uses each profile timezone", () => {
    expect(up).toContain("v.representative_id");
    expect(up).toContain("t.assigned_to");
    expect(up).toContain("p.timezone");
    expect(up).not.toContain("Europe/Istanbul");
  });

  it("excludes terminal visits/tasks and applies missed tolerance", () => {
    expect(up).toContain("v.completed_at is null");
    expect(up).toContain(
      "v.status not in ('approved', 'rejected', 'archived')",
    );
    expect(up).toContain("t.status = 'open'");
    expect(up).toContain("interval '30 minutes'");
  });

  it("ships a reversible migration", () => {
    expect(down).toContain("drop function if exists public.process_reminders");
    expect(down).toContain(
      "drop table if exists public.notification_preferences",
    );
    expect(down).toContain("drop column if exists occurrence_key");
  });
});
