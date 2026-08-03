"use client";

export default function ErrorPage({ reset }: { reset: () => void }) {
  return (
    <main style={{ padding: 48 }}>
      <h1>Bir sorun oluştu</h1>
      <p>Veriler yüklenemedi. Saha kaydınız kaybolmadı.</p>
      <button onClick={reset}>Tekrar dene</button>
    </main>
  );
}
