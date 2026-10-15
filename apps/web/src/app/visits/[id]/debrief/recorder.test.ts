import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { selectVisitRecordingMimeType } from "@/lib/visit-audio-format";
import { DebriefRecorder } from "./recorder";

describe("visit debrief recorder localization", () => {
  it("shows English interface copy and an explicit note-language selector", () => {
    const html = renderToStaticMarkup(
      createElement(DebriefRecorder, {
        visitId: "visit-1",
        ownerId: "owner-1",
        locale: "en",
      }),
    );
    expect(html).toContain("Voice note");
    expect(html).toContain("Language of the note and audio");
    expect(html).toContain("separate from the interface language");
    expect(html).toContain('value="en" selected=""');
  });

  it("preserves the Turkish interface while offering English note processing", () => {
    const html = renderToStaticMarkup(
      createElement(DebriefRecorder, {
        visitId: "visit-1",
        ownerId: "owner-1",
        locale: "tr",
      }),
    );
    expect(html).toContain("Sesli not");
    expect(html).toContain("Not ve ses dili");
    expect(html).toContain('value="tr" selected=""');
    expect(html).toContain('<option value="en">İngilizce</option>');
  });
});

describe("visit audio recorder browser formats", () => {
  it("prefers WebM where available and falls back to Safari-compatible MP4", () => {
    expect(selectVisitRecordingMimeType((mime) => mime === "audio/webm")).toBe(
      "audio/webm",
    );
    expect(selectVisitRecordingMimeType((mime) => mime === "audio/mp4")).toBe(
      "audio/mp4",
    );
    expect(selectVisitRecordingMimeType(() => false)).toBeUndefined();
  });
});
