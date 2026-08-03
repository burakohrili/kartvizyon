import { visitSummarySchema, type VisitSummary } from "@kartvizyon/contracts";
import OpenAI from "openai";
import { zodTextFormat } from "openai/helpers/zod";

const SUMMARY_MODEL = process.env.OPENAI_SUMMARY_MODEL ?? "gpt-5.6-sol";
const TRANSCRIPTION_MODEL =
  process.env.OPENAI_TRANSCRIPTION_MODEL ?? "gpt-4o-transcribe";

function client() {
  if (!process.env.OPENAI_API_KEY) {
    throw new Error("OPENAI_API_KEY_MISSING");
  }
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
}

export async function transcribeVisitAudio(file: File) {
  const result = await client().audio.transcriptions.create({
    file,
    model: TRANSCRIPTION_MODEL,
    language: "tr",
    prompt:
      "Türkçe saha satış ziyareti sonrası kişisel değerlendirme. Firma, teklif, takip ve tarih ifadelerini doğru yaz.",
  });

  return {
    text: result.text.trim(),
    model: TRANSCRIPTION_MODEL,
    usage: result.usage,
  };
}

export async function summarizeVisitTranscript(transcript: string): Promise<{
  summary: VisitSummary;
  model: string;
  usage: { inputTokens: number; outputTokens: number };
}> {
  const response = await client().responses.parse({
    model: SUMMARY_MODEL,
    input: [
      {
        role: "system",
        content:
          "Sen KartVizyon saha satış asistanısın. Yalnızca verilen ziyaret sonrası nottan doğrulanabilir bilgileri çıkar. Bilgi uydurma. Belirsiz tarihleri veya sorumluları null bırak. Sağlık, kimlik, finansal hesap, özel hayat veya benzeri hassas kişisel veri varsa sensitiveContentDetected=true yap. Çıktı kullanıcı onayı olmadan kurumsal kayıt değildir.",
      },
      {
        role: "user",
        content: `Ziyaret sonrası kişisel değerlendirme:\n\n${transcript}`,
      },
    ],
    text: {
      format: zodTextFormat(visitSummarySchema, "visit_summary"),
    },
  });

  if (!response.output_parsed) throw new Error("AI_SUMMARY_EMPTY");

  return {
    summary: visitSummarySchema.parse(response.output_parsed),
    model: SUMMARY_MODEL,
    usage: {
      inputTokens: response.usage?.input_tokens ?? 0,
      outputTokens: response.usage?.output_tokens ?? 0,
    },
  };
}

export const visitAiLimits = {
  maxAudioBytes: 25 * 1024 * 1024,
  maxTranscriptCharacters: 20_000,
  acceptedAudioTypes: new Set([
    "audio/webm",
    "audio/mp4",
    "audio/mpeg",
    "audio/wav",
    "audio/x-m4a",
  ]),
};
