export type QueuedDebrief = {
  clientMutationId: string;
  ownerId: string;
  visitId: string;
  transcript: string;
  audio: Blob | null;
  createdAt: string;
  attempts: number;
};

const DATABASE = "kartvizyon-offline";
const STORE = "debriefs";

function database(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DATABASE, 1);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE)) {
        const store = db.createObjectStore(STORE, {
          keyPath: "clientMutationId",
        });
        store.createIndex("ownerId", "ownerId");
      }
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function transaction<T>(
  mode: IDBTransactionMode,
  operation: (store: IDBObjectStore) => IDBRequest<T>,
) {
  const db = await database();
  return new Promise<T>((resolve, reject) => {
    const tx = db.transaction(STORE, mode);
    const request = operation(tx.objectStore(STORE));
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
    tx.oncomplete = () => db.close();
  });
}

function announceQueueChange() {
  window.dispatchEvent(new Event("kartvizyon:queue-change"));
}

export async function enqueueDebrief(item: QueuedDebrief) {
  await transaction("readwrite", (store) => store.put(item));
  announceQueueChange();
}

export async function queuedDebriefs(ownerId: string) {
  const all = await transaction<QueuedDebrief[]>("readonly", (store) =>
    store.getAll(),
  );
  return all
    .filter((item) => item.ownerId === ownerId)
    .sort((a, b) => a.createdAt.localeCompare(b.createdAt));
}

export async function queuedDebriefCount(ownerId: string) {
  return (await queuedDebriefs(ownerId)).length;
}

async function removeDebrief(clientMutationId: string) {
  await transaction("readwrite", (store) => store.delete(clientMutationId));
  announceQueueChange();
}

export async function syncQueuedDebriefs(ownerId: string) {
  if (!navigator.onLine)
    return { synced: 0, remaining: await queuedDebriefCount(ownerId) };
  let synced = 0;

  for (const item of await queuedDebriefs(ownerId)) {
    const form = new FormData();
    form.set("clientMutationId", item.clientMutationId);
    if (item.transcript) form.set("transcript", item.transcript);
    if (item.audio) form.set("audio", item.audio, "ziyaret-notu.webm");

    try {
      const response = await fetch(`/api/visits/${item.visitId}/debrief`, {
        method: "POST",
        body: form,
      });
      if (!response.ok) break;
      await removeDebrief(item.clientMutationId);
      synced += 1;
    } catch {
      break;
    }
  }

  return { synced, remaining: await queuedDebriefCount(ownerId) };
}
