"use client";

import { useState } from "react";
import type { AppLocale } from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";

type Item = Record<string, unknown>;

export function OrganizationStructure({
  workspaceId,
  initialRegions,
  initialTeams,
  locale,
}: {
  workspaceId: string;
  initialRegions: Item[];
  initialTeams: Item[];
  locale: AppLocale;
}) {
  const m = getMessages(locale).workspaceAdmin;
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
      setMessage(m.regionCreated);
    } else setMessage(m.regionFailed);
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
      setMessage(m.teamCreated);
    } else setMessage(m.teamFailed);
  }
  return (
    <div className="operations-grid">
      <div>
        <form action={createRegion} className="operation-form">
          <h2>{m.createRegion}</h2>
          <label>
            {m.regionName}
            <input name="name" required minLength={2} />
          </label>
          <button className="primary">{m.create}</button>
        </form>
        <form
          action={createTeam}
          className="operation-form structure-team-form"
        >
          <h2>{m.createTeam}</h2>
          <label>
            {m.teamName}
            <input name="name" required minLength={2} />
          </label>
          <label>
            {m.region}
            <select name="regionId">
              <option value="">{m.noRegion}</option>
              {regions.map((region) => (
                <option key={String(region.id)} value={String(region.id)}>
                  {String(region.name)}
                </option>
              ))}
            </select>
          </label>
          <button className="primary">{m.create}</button>
        </form>
        {message && <p className="form-message">{message}</p>}
      </div>
      <section className="operation-list">
        <h2>{m.organizationStructure}</h2>
        {regions.map((region) => (
          <article key={String(region.id)}>
            <div>
              <strong>{String(region.name)}</strong>
              <small>{m.region}</small>
            </div>
          </article>
        ))}
        {teams.map((team) => {
          const region = team.region as { name?: string } | null;
          return (
            <article key={String(team.id)}>
              <div>
                <strong>{String(team.name)}</strong>
                <small>
                  {m.createTeam} · {region?.name ?? m.noRegion}
                </small>
              </div>
            </article>
          );
        })}
      </section>
    </div>
  );
}
