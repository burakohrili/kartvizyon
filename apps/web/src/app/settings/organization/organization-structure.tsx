"use client";

import { useState } from "react";

type Item = Record<string, unknown>;

export function OrganizationStructure({
  workspaceId,
  initialRegions,
  initialTeams,
}: {
  workspaceId: string;
  initialRegions: Item[];
  initialTeams: Item[];
}) {
  const [regions, setRegions] = useState(initialRegions);
  const [teams, setTeams] = useState(initialTeams);
  const [message, setMessage] = useState("");
  async function createRegion(formData: FormData) {
    const response = await fetch("/api/organization/structure", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        kind: "region",
        data: { workspaceId, name: formData.get("name"), parentRegionId: null },
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setRegions((current) => [...current, result.data]);
      setMessage("Bölge oluşturuldu.");
    } else setMessage(result.error ?? "Bölge oluşturulamadı.");
  }
  async function createTeam(formData: FormData) {
    const response = await fetch("/api/organization/structure", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        kind: "team",
        data: {
          workspaceId,
          name: formData.get("name"),
          regionId: formData.get("regionId") || null,
          managerId: null,
        },
      }),
    });
    const result = await response.json();
    if (response.ok) {
      setTeams((current) => [...current, result.data]);
      setMessage("Takım oluşturuldu.");
    } else setMessage(result.error ?? "Takım oluşturulamadı.");
  }
  return (
    <div className="operations-grid">
      <div>
        <form action={createRegion} className="operation-form">
          <h2>Bölge oluştur</h2>
          <label>
            Bölge adı
            <input name="name" required minLength={2} />
          </label>
          <button className="primary">Oluştur</button>
        </form>
        <form
          action={createTeam}
          className="operation-form structure-team-form"
        >
          <h2>Takım oluştur</h2>
          <label>
            Takım adı
            <input name="name" required minLength={2} />
          </label>
          <label>
            Bölge
            <select name="regionId">
              <option value="">Bölgesiz</option>
              {regions.map((region) => (
                <option key={String(region.id)} value={String(region.id)}>
                  {String(region.name)}
                </option>
              ))}
            </select>
          </label>
          <button className="primary">Oluştur</button>
        </form>
        {message && <p className="form-message">{message}</p>}
      </div>
      <section className="operation-list">
        <h2>Organizasyon yapısı</h2>
        {regions.map((region) => (
          <article key={String(region.id)}>
            <div>
              <strong>{String(region.name)}</strong>
              <small>Bölge</small>
            </div>
          </article>
        ))}
        {teams.map((team) => {
          const region = team.region as { name?: string } | null;
          return (
            <article key={String(team.id)}>
              <div>
                <strong>{String(team.name)}</strong>
                <small>Takım · {region?.name ?? "Bölgesiz"}</small>
              </div>
            </article>
          );
        })}
      </section>
    </div>
  );
}
