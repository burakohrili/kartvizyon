const DEFAULT_AUDIO_BUCKET = "visit-audio";
const STORAGE_BUCKET_PATTERN = /^[a-z0-9][a-z0-9_-]{0,62}$/;

export function audioBucketName(value = process.env.SUPABASE_AUDIO_BUCKET) {
  const normalized = value
    ?.trim()
    .replace(/^(['"])(.*)\1$/, "$2")
    .trim();
  return normalized && STORAGE_BUCKET_PATTERN.test(normalized)
    ? normalized
    : DEFAULT_AUDIO_BUCKET;
}
