import { Firestore } from "firebase-admin/firestore";

import healthCollectionRoots from "./health_collection_roots.json";

/** Health-owned collection roots under users/{uid}. Authoritative purge list. */
export const HEALTH_COLLECTION_ROOTS = healthCollectionRoots as readonly string[];

/**
 * Recursively deletes all approved health collection roots.
 * Missing collections are treated as already clean by the Admin SDK.
 */
export async function purgeHealthFirestore(db: Firestore, uid: string): Promise<void> {
  const userRef = db.collection("users").doc(uid);

  for (const name of HEALTH_COLLECTION_ROOTS) {
    await db.recursiveDelete(userRef.collection(name));
  }
}

/**
 * Recursively deletes users/{uid} including all descendants.
 * Retries remain safe when the parent is already absent but children remain.
 */
export async function purgeAccountFirestore(db: Firestore, uid: string): Promise<void> {
  await db.recursiveDelete(db.collection("users").doc(uid));
}
