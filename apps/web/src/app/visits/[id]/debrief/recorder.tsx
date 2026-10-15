"use client";

import { useRef, useState } from "react";
import { enqueueDebrief } from "@/lib/offline/debrief-queue";
import type { AppLocale } from "@/lib/i18n/locale";
import { intlLocale } from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";
import {
  selectVisitRecordingMimeType,
  visitAudioFileName,
} from "@/lib/visit-audio-format";

type State = "idle" | "recording" | "ready" | "processing" | "queued" | "error";

export function DebriefRecorder({
  visitId,
  ownerId,
  locale,
}: {
  visitId: string;
  ownerId: string;
  locale: AppLocale;
}) {
  const m = getMessages(locale).debrief;
  const [state, setState] = useState<State>("idle");
  const [audio, setAudio] = useState<Blob | null>(null);
  const [language, setLanguage] = useState<"en" | "tr">(locale);
  const [elapsed, setElapsed] = useState(0);
  const [error, setError] = useState("");
  const recorder = useRef<MediaRecorder | null>(null);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);
  const mutationId = useRef(crypto.randomUUID());

  async function saveForSync(transcript: string) {
    localStorage.setItem("kartvizyon:offline-owner", ownerId);
    await enqueueDebrief({
      clientMutationId: mutationId.current,
      ownerId,
      visitId,
      transcript,
      language,
      audio,
      createdAt: new Date().toISOString(),
      attempts: 0,
    });
    setState("queued");
  }

  async function queueForSync(transcript: string) {
    try {
      await saveForSync(transcript);
    } catch {
      setError(m.offlineSaveFailed);
      setState(audio ? "ready" : "error");
    }
  }

  async function startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const chunks: Blob[] = [];
      const mimeType = selectVisitRecordingMimeType((type) =>
        MediaRecorder.isTypeSupported(type),
      );
      const mediaRecorder = mimeType
        ? new MediaRecorder(stream, { mimeType })
        : new MediaRecorder(stream);
      recorder.current = mediaRecorder;
      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size) chunks.push(event.data);
      };
      mediaRecorder.onstop = () => {
        const recordedType = mediaRecorder.mimeType || mimeType || "audio/webm";
        setAudio(new Blob(chunks, { type: recordedType }));
        stream.getTracks().forEach((track) => track.stop());
        setState("ready");
      };
      mediaRecorder.start();
      setElapsed(0);
      setState("recording");
      timer.current = setInterval(() => {
        setElapsed((seconds) => {
          if (seconds >= 89) stopRecording();
          return seconds + 1;
        });
      }, 1000);
    } catch {
      setError(m.microphoneError);
      setState("error");
    }
  }

  function stopRecording() {
    if (timer.current) clearInterval(timer.current);
    if (recorder.current?.state === "recording") recorder.current.stop();
  }

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setState("processing");
    setError("");
    const data = new FormData(event.currentTarget);
    const transcript = String(data.get("transcript") ?? "").trim();
    data.set("clientMutationId", mutationId.current);
    data.set("language", language);
    if (audio) data.set("audio", audio, visitAudioFileName(audio.type));
    if (!audio && transcript.length < 10) {
      setError(m.minimumNote);
      setState("error");
      return;
    }

    if (!navigator.onLine) {
      await queueForSync(transcript);
      return;
    }

    try {
      const response = await fetch(`/api/visits/${visitId}/debrief`, {
        method: "POST",
        body: data,
      });
      const result = (await response.json()) as { reviewUrl?: string };
      if (!response.ok || !result.reviewUrl) {
        const messages = new Map<number, string>([
          [401, m.signInRequired],
          [402, m.quotaExceeded],
          [404, m.visitUnavailable],
          [409, m.alreadyProcessing],
          [413, m.audioTooLarge],
          [415, m.audioUnsupported],
          [422, m.audioInvalid],
          [429, m.rateLimited],
          [503, m.serviceUnavailable],
        ]);
        throw messages.get(response.status) ?? m.submitFailed;
      }
      window.location.assign(result.reviewUrl);
    } catch (submissionError) {
      if (!navigator.onLine || submissionError instanceof TypeError) {
        await queueForSync(transcript);
        return;
      }
      setError(
        typeof submissionError === "string" ? submissionError : m.submitFailed,
      );
      setState(audio ? "ready" : "error");
    }
  }

  return (
    <form onSubmit={submit} className="debrief-form">
      <div
        className={`recorder-panel ${state === "recording" ? "active" : ""}`}
      >
        <div>
          <strong>{state === "recording" ? m.recording : m.voiceNote}</strong>
          <small>
            {state === "recording"
              ? `${new Intl.NumberFormat(intlLocale(locale)).format(elapsed)} ${m.seconds} / 90 ${m.seconds}`
              : audio
                ? m.ready
                : m.maxDuration}
          </small>
        </div>
        {state === "recording" ? (
          <button
            type="button"
            onClick={stopRecording}
            className="reject-button"
          >
            {m.stop}
          </button>
        ) : (
          <button
            type="button"
            onClick={startRecording}
            disabled={state === "processing"}
          >
            {audio ? m.recordAgain : m.start}
          </button>
        )}
      </div>

      <div className="debrief-divider">
        <span>{m.orType}</span>
      </div>
      <label className="review-field">
        {m.languageLabel}
        <select
          name="language"
          value={language}
          onChange={(event) =>
            setLanguage(event.target.value === "en" ? "en" : "tr")
          }
          disabled={state === "processing" || state === "queued"}
        >
          <option value="tr">{m.turkish}</option>
          <option value="en">{m.english}</option>
        </select>
      </label>
      <p className="privacy-note">{m.languageHint}</p>
      <label className="review-field">
        {m.noteLabel}
        <textarea
          name="transcript"
          rows={7}
          maxLength={20000}
          placeholder={m.notePlaceholder}
        />
      </label>
      <p className="privacy-note">{m.privacy}</p>
      {state === "queued" && (
        <p className="offline-saved" role="status">
          {m.queued}
        </p>
      )}
      {error && (
        <p className="form-error" role="alert">
          {error}
        </p>
      )}
      <button
        className="primary debrief-submit"
        disabled={
          state === "processing" || state === "recording" || state === "queued"
        }
      >
        {state === "processing"
          ? m.processing
          : state === "queued"
            ? m.waitingSync
            : m.prepare}
      </button>
    </form>
  );
}
