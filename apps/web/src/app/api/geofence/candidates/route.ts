import {
  calculateVisitPriority,
  haversineDistanceKm,
} from "@kartvizyon/contracts";
import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const url = new URL(request.url);
  const workspaceId = url.searchParams.get("workspaceId");
  const latitude = Number(url.searchParams.get("latitude"));
  const longitude = Number(url.searchParams.get("longitude"));
  // Harita ekranı geniş listeyi ister; saha modu bildirimi yalnız gerçekten
  // yakındakini bildirmeli. Varsayılan korunur ki mevcut çağrılar değişmesin.
  const requestedRadius = Number(url.searchParams.get("maxDistanceKm"));
  const maxDistanceKm =
    Number.isFinite(requestedRadius) && requestedRadius > 0
      ? Math.min(requestedRadius, 25)
      : 25;
  if (
    !workspaceId ||
    !Number.isFinite(latitude) ||
    latitude < -90 ||
    latitude > 90 ||
    !Number.isFinite(longitude) ||
    longitude < -180 ||
    longitude > 180
  ) {
    return Response.json(
      { error: "Geçerli çalışma alanı ve konum gereklidir." },
      { status: 400 },
    );
  }
  const supabase = await createSupabaseServerClient(request);
  if (!supabase) return serviceUnavailable();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return Response.json({ error: "Oturum gerekli." }, { status: 401 });
  const [
    { data: companies, error },
    { data: visits },
    { data: tasks },
    { data: cooldowns },
  ] = await Promise.all([
    supabase
      .from("companies")
      .select("id,name,address,latitude,longitude")
      .eq("workspace_id", workspaceId)
      .not("latitude", "is", null)
      .not("longitude", "is", null)
      .is("archived_at", null)
      .limit(500),
    supabase
      .from("visits")
      .select("company_id,approved_at")
      .eq("workspace_id", workspaceId)
      .eq("status", "approved")
      .order("approved_at", { ascending: false }),
    supabase
      .from("tasks")
      .select("company_id,due_at")
      .eq("workspace_id", workspaceId)
      .eq("status", "open")
      .lt("due_at", new Date().toISOString()),
    supabase
      .from("geofence_events")
      .select("company_id,occurred_at")
      .eq("workspace_id", workspaceId)
      .eq("user_id", user.id)
      .eq("outcome", "shown")
      .gte("occurred_at", new Date(Date.now() - 86_400_000).toISOString()),
  ]);
  if (error) return apiError(error);
  const lastVisits = new Map<string, string>();
  visits?.forEach((visit) => {
    if (!lastVisits.has(visit.company_id))
      lastVisits.set(visit.company_id, visit.approved_at);
  });
  const overdue = new Map<string, number>();
  tasks?.forEach((task) => {
    if (task.company_id)
      overdue.set(task.company_id, (overdue.get(task.company_id) ?? 0) + 1);
  });
  const coolingDown = new Set(cooldowns?.map((event) => event.company_id));
  const now = Date.now();
  const candidates = (companies ?? [])
    .filter((company) => !coolingDown.has(company.id))
    .map((company) => {
      const distanceKm = haversineDistanceKm(
        { latitude, longitude },
        {
          latitude: Number(company.latitude),
          longitude: Number(company.longitude),
        },
      );
      const lastVisit = lastVisits.get(company.id);
      const daysSinceVisit = lastVisit
        ? Math.floor((now - new Date(lastVisit).getTime()) / 86_400_000)
        : null;
      const priority = calculateVisitPriority({
        daysSinceVisit,
        overdueTaskCount: overdue.get(company.id) ?? 0,
        customerValue: 0.5,
        distanceKm,
      });
      return {
        ...company,
        distanceKm,
        priority,
        // Bildirim metni "en son ne zaman uğradın" diyebilsin diye ham
        // değerler de döner; şimdiye kadar yalnız puana giriyorlardı.
        lastVisitAt: lastVisit ?? null,
        daysSinceVisit,
        overdueTaskCount: overdue.get(company.id) ?? 0,
      };
    })
    .filter((candidate) => candidate.distanceKm <= maxDistanceKm)
    .sort((a, b) => b.priority.total - a.priority.total)
    .slice(0, 20);
  return Response.json({
    data: candidates,
    locationStored: false,
    cooldownHours: 24,
    maxDistanceKm,
  });
}
