import OpenAI from "openai";

export function normalizeOpenAiApiKey(value: string | undefined): string {
  const apiKey = value?.replaceAll("\uFEFF", "").trim();
  if (!apiKey) throw new Error("OPENAI_API_KEY_MISSING");
  return apiKey;
}

export function createOpenAiClient(): OpenAI {
  return new OpenAI({
    apiKey: normalizeOpenAiApiKey(process.env.OPENAI_API_KEY),
  });
}
