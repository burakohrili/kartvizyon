import { describe, expect, it } from "vitest";
import {
  normalizeVisitAudioMimeType,
  selectVisitRecordingMimeType,
  visitAudioFileName,
} from "./visit-audio-format";

describe("visit audio formats", () => {
  it("normalizes codec parameters while preserving supported container types", () => {
    expect(normalizeVisitAudioMimeType(" Audio/MP4; codecs=mp4a.40.2 ")).toBe(
      "audio/mp4",
    );
    expect(normalizeVisitAudioMimeType("audio/webm;codecs=opus")).toBe(
      "audio/webm",
    );
  });

  it("uses matching file extensions for direct and queued uploads", () => {
    expect(visitAudioFileName("audio/mp4; codecs=mp4a.40.2")).toBe(
      "visit-note.m4a",
    );
    expect(visitAudioFileName("audio/mpeg")).toBe("visit-note.mp3");
    expect(visitAudioFileName("audio/wav")).toBe("visit-note.wav");
    expect(visitAudioFileName("audio/webm;codecs=opus")).toBe(
      "visit-note.webm",
    );
  });

  it("selects only a browser-supported recording format in priority order", () => {
    expect(selectVisitRecordingMimeType((type) => type === "audio/webm")).toBe(
      "audio/webm",
    );
    expect(selectVisitRecordingMimeType((type) => type === "audio/mp4")).toBe(
      "audio/mp4",
    );
    expect(selectVisitRecordingMimeType(() => false)).toBeUndefined();
  });
});
