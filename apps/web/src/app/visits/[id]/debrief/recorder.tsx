"use client";

import { useRef, useState } from "react";
import { enqueueDebrief } from "@/lib/offline/debrief-queue";

type State = "idle" | "recording" | "ready" | "processing" | "queued" | "error";

export function DebriefRecorder({
  visitId,
  ownerId,
}: {
  visitId: string;
  ownerId: string;
}) {
  const [state, setState] = useState<State>("idle");
  const [audio, setAudio] = useState<Blob | null>(null);
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
      audio,
      createdAt: new Date().toISOString(),
      attempts: 0,
    });
    setState("queued");
  }

  async function startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const chunks: Blob[] = [];
      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: "audio/webm",
      });
      recorder.current = mediaRecorder;
      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size) chunks.push(event.data);
      };
      mediaRecorder.onstop = () => {
        setAudio(new Blob(chunks, { type: "audio/webm" }));
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
      setError("Mikrofona erişilemedi. Metin alanını kullanabilirsin.");
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
    if (audio) data.set("audio", audio, "ziyaret-notu.webm");
    if (!audio && transcript.length < 10) {
      setError("En az 10 karakterlik bir not yazın veya ses kaydedin.");
      setState("error");
      return;
    }

    if (!navigator.onLine) {
      await saveForSync(transcript);
      return;
    }

    try {
      const response = await fetch(`/api/visits/${visitId}/debrief`, {
        method: "POST",
        body: data,
      });
      const result = (await response.json()) as {
        error?: string;
        reviewUrl?: string;
      };
      if (!response.ok || !result.reviewUrl) {
        throw new Error(result.error ?? "AI özeti hazırlanamadı.");
      }
      window.location.assign(result.reviewUrl);
    } catch (submissionError) {
      if (!navigator.onLine || submissionError instanceof TypeError) {
        await saveForSync(transcript);
        return;
      }
      setError(
        submissionError instanceof Error
          ? submissionError.message
          : "İşlem tamamlanamadı.",
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
          <strong>
            {state === "recording" ? "Kayıt sürüyor" : "Sesli not"}
          </strong>
          <small>
            {state === "recording"
              ? `${elapsed} sn / 90 sn`
              : audio
                ? "Kayıt hazır"
                : "En fazla 90 saniye"}
          </small>
        </div>
        {state === "recording" ? (
          <button
            type="button"
            onClick={stopRecording}
            className="reject-button"
          >
            Kaydı bitir
          </button>
        ) : (
          <button
            type="button"
            onClick={startRecording}
            disabled={state === "processing"}
          >
            {audio ? "Yeniden kaydet" : "Kayda başla"}
          </button>
        )}
      </div>

      <div className="debrief-divider">
        <span>veya yazarak anlat</span>
      </div>
      <label className="review-field">
        Ziyaret notu
        <textarea
          name="transcript"
          rows={7}
          maxLength={20000}
          placeholder="Kimle görüştün, ihtiyaç neydi, ne söz verdin ve sıradaki adım ne?"
        />
      </label>
      <p className="privacy-note">
        AI taslağı sen inceleyip onaylamadan yöneticilere veya kurumsal hafızaya
        aktarılmaz.
      </p>
      {state === "queued" && (
        <p className="offline-saved" role="status">
          ✓ Not cihazda güvenle saklandı. Bağlantı gelince otomatik
          gönderilecek.
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
          ? "AI özeti hazırlanıyor…"
          : state === "queued"
            ? "Senkronizasyon bekleniyor"
            : "Özeti hazırla"}
      </button>
    </form>
  );
}
