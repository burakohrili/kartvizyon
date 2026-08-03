import { z } from "zod";

export const priorityInputSchema = z.object({
  daysSinceVisit: z.number().min(0).max(3650).nullable(),
  overdueTaskCount: z.number().int().min(0).max(100),
  customerValue: z.number().min(0).max(1),
  distanceKm: z.number().min(0).max(500),
});

export type PriorityInput = z.infer<typeof priorityInputSchema>;
export type PriorityScore = {
  total: number;
  reasons: Array<{ label: string; points: number }>;
};

export function calculateVisitPriority(rawInput: PriorityInput): PriorityScore {
  const input = priorityInputSchema.parse(rawInput);
  const recency =
    input.daysSinceVisit === null
      ? 35
      : Math.min(35, Math.round((input.daysSinceVisit / 90) * 35));
  const followUp = Math.min(25, input.overdueTaskCount * 10);
  const value = Math.round(input.customerValue * 20);
  const distance = Math.max(0, Math.round(20 - input.distanceKm * 2));
  return {
    total: recency + followUp + value + distance,
    reasons: [
      {
        label:
          input.daysSinceVisit === null
            ? "Henüz ziyaret edilmedi"
            : `Son ziyaret ${input.daysSinceVisit} gün önce`,
        points: recency,
      },
      { label: `${input.overdueTaskCount} geciken takip`, points: followUp },
      { label: "Müşteri değeri", points: value },
      { label: `${input.distanceKm.toFixed(1)} km mesafede`, points: distance },
    ].filter((reason) => reason.points > 0),
  };
}

export function haversineDistanceKm(
  from: { latitude: number; longitude: number },
  to: { latitude: number; longitude: number },
): number {
  const radius = 6371;
  const radians = (degree: number) => (degree * Math.PI) / 180;
  const latitudeDelta = radians(to.latitude - from.latitude);
  const longitudeDelta = radians(to.longitude - from.longitude);
  const value =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(radians(from.latitude)) *
      Math.cos(radians(to.latitude)) *
      Math.sin(longitudeDelta / 2) ** 2;
  return radius * 2 * Math.atan2(Math.sqrt(value), Math.sqrt(1 - value));
}
