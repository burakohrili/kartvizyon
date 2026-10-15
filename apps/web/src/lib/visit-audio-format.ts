export function normalizeVisitAudioMimeType(mimeType: string): string {
  return mimeType.split(";", 1)[0].trim().toLowerCase();
}

export function visitAudioFileName(mimeType: string): string {
  const extension =
    {
      "audio/mp4": "m4a",
      "audio/x-m4a": "m4a",
      "audio/mpeg": "mp3",
      "audio/wav": "wav",
    }[normalizeVisitAudioMimeType(mimeType)] ?? "webm";
  return `visit-note.${extension}`;
}

export function selectVisitRecordingMimeType(
  isSupported: (mimeType: string) => boolean,
): string | undefined {
  return ["audio/webm", "audio/mp4", "audio/mpeg", "audio/wav"].find(
    isSupported,
  );
}
