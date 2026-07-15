import {randomUUID} from "node:crypto";

import {FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";

const LEASE_PATH = "__sheetSyncInternal/sheetWriteLease";
const LEASE_DURATION_MS = 60_000;
const MAX_WAIT_MS = 55_000;

function delay(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

export async function withSheetWriteLease<T>(operation: () => Promise<T>): Promise<T> {
  const firestore = getFirestore();
  const leaseRef = firestore.doc(LEASE_PATH);
  const owner = randomUUID();
  const deadline = Date.now() + MAX_WAIT_MS;

  while (true) {
    const acquired = await firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(leaseRef);
      const current = snapshot.data();
      const expiresAt = current?.expiresAt;
      const expired = !(expiresAt instanceof Timestamp) || expiresAt.toMillis() <= Date.now();
      if (snapshot.exists && !expired) return false;
      transaction.set(leaseRef, {
        owner,
        expiresAt: Timestamp.fromMillis(Date.now() + LEASE_DURATION_MS),
        acquiredAt: FieldValue.serverTimestamp(),
      });
      return true;
    });

    if (acquired) break;
    if (Date.now() >= deadline) throw new Error("Timed out waiting for the Sheets write lease");
    await delay(250 + Math.floor(Math.random() * 500));
  }

  try {
    return await operation();
  } finally {
    await firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(leaseRef);
      if (snapshot.data()?.owner === owner) transaction.delete(leaseRef);
    });
  }
}
