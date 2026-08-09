import { FieldValue, Firestore } from "firebase-admin/firestore";

import { PurgeMode } from "./auth";

export const DELETION_IN_PROGRESS = "deletionInProgress";
export const DELETION_STARTED_AT = "deletionStartedAt";

/**
 * Sets the server-owned deletion guard on users/{uid}.
 *
 * Clients cannot write these fields (enforced by Firestore rules).
 * Cloud Storage rules observe the same document via firestore.get/exists.
 */
export async function setDeletionGuard(
  db: Firestore,
  uid: string,
  mode: PurgeMode,
): Promise<void> {
  await db.collection("users").doc(uid).set(
    {
      [DELETION_IN_PROGRESS]: mode,
      [DELETION_STARTED_AT]: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

/**
 * Clears the deletion guard after a successful health-mode purge.
 * Account mode removes the root document entirely, so clearing is unnecessary.
 */
export async function clearDeletionGuard(db: Firestore, uid: string): Promise<void> {
  await db.collection("users").doc(uid).set(
    {
      [DELETION_IN_PROGRESS]: FieldValue.delete(),
      [DELETION_STARTED_AT]: FieldValue.delete(),
    },
    { merge: true },
  );
}
