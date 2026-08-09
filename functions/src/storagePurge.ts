import { getStorage } from "firebase-admin/storage";

/**
 * Deletes every object under the given prefix.
 * Missing prefix / empty listing is clean.
 * Does not depend on Firestore report metadata (orphan-safe).
 */
export async function deleteStoragePrefix(prefix: string): Promise<void> {
  const bucket = getStorage().bucket();
  // deleteFiles paginates internally. force:true avoids failing when empty.
  await bucket.deleteFiles({ prefix, force: true });
}

export function healthReportsPrefix(uid: string): string {
  return `users/${uid}/reports/`;
}

export function accountUserPrefix(uid: string): string {
  return `users/${uid}/`;
}
