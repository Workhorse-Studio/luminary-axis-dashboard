import {getFirestore} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

import type {ManagedDocument, ManagedSheetConfig, SyncConfig} from "./types.js";
import {withSheetWriteLease} from "./lease.js";
import {SheetsStore} from "./sheets.js";

function snapshotVersion(snapshot: {updateTime?: {toDate(): Date}}): string {
  return snapshot.updateTime?.toDate().toISOString() ?? new Date(0).toISOString();
}

function toManagedDocument(
  snapshot: {
    id: string;
    data(): Record<string, unknown> | undefined;
    updateTime?: {toDate(): Date};
  },
  parentId?: string,
): ManagedDocument {
  return {
    id: snapshot.id,
    parentId,
    data: snapshot.data() ?? {},
    version: snapshotVersion(snapshot),
  };
}

export async function loadDocumentsForMapping(
  mapping: ManagedSheetConfig,
): Promise<ManagedDocument[]> {
  const firestore = getFirestore();
  if (!mapping.firestorePattern.includes("{")) {
    const snapshot = await firestore.doc(mapping.firestorePattern).get();
    return snapshot.exists ? [toManagedDocument(snapshot)] : [];
  }

  if (mapping.parentId) {
    const collectionId = mapping.firestorePattern.split("/").at(-2);
    if (!collectionId) throw new Error(`Invalid collection-group pattern: ${mapping.firestorePattern}`);
    const snapshots = await firestore.collectionGroup(collectionId).get();
    return snapshots.docs
      .filter((snapshot) => {
        const segments = snapshot.ref.path.split("/");
        return segments.length === 4 &&
          segments[0] === "classes" &&
          segments[2] === collectionId;
      })
      .map((snapshot) => toManagedDocument(snapshot, snapshot.ref.parent.parent?.id));
  }

  const collectionPath = mapping.firestorePattern.replace(/\/\{docId\}$/, "");
  const snapshots = await firestore.collection(collectionPath).get();
  return snapshots.docs.map((snapshot) => toManagedDocument(snapshot));
}

export async function loadAllManagedDocuments(
  config: SyncConfig,
): Promise<Map<string, ManagedDocument[]>> {
  const entries = await Promise.all(
    config.managedSheets.map(async (mapping) => [
      mapping.id,
      await loadDocumentsForMapping(mapping),
    ] as const),
  );
  return new Map(entries);
}

interface FirestoreWriteEventLike {
  id: string;
  time: string;
  data?: {
    before?: {
      exists: boolean;
      id: string;
      ref: {path: string};
      data(): Record<string, unknown> | undefined;
      updateTime?: {toDate(): Date};
    };
    after?: {
      exists: boolean;
      id: string;
      ref: {path: string};
      data(): Record<string, unknown> | undefined;
      updateTime?: {toDate(): Date};
    };
  };
  params: Record<string, string>;
}

export async function syncFirestoreWrite(
  config: SyncConfig,
  mapping: ManagedSheetConfig,
  event: FirestoreWriteEventLike,
): Promise<void> {
  const before = event.data?.before;
  const after = event.data?.after;
  const eventSnapshot = after?.exists ? after : before;
  if (!eventSnapshot) {
    logger.warn("Firestore sync event had no snapshot", {eventId: event.id, mapping: mapping.id});
    return;
  }

  const current = await getFirestore().doc(eventSnapshot.ref.path).get();
  const parentId = mapping.parentId ? event.params.parentId : undefined;
  const document: ManagedDocument = current.exists
    ? toManagedDocument(current, parentId)
    : {
        id: event.params.docId ?? eventSnapshot.id,
        parentId,
        data: before?.data() ?? {},
        version: event.time,
        deleted: true,
      };

  await withSheetWriteLease(async () => {
    await new SheetsStore(config).upsertDocument(mapping, document);
  });
  logger.info("Synchronized Firestore document to Sheets", {
    eventId: event.id,
    mapping: mapping.id,
    docId: document.id,
    parentId,
    deleted: document.deleted === true,
  });
}
