import { getFirestore } from "firebase-admin/firestore";
import { CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

import {
  parsePurgeMode,
  requireAuthenticatedUid,
  requireRecentAuth,
} from "./auth";
import { clearDeletionGuard, setDeletionGuard } from "./guard";
import { invalidArgument, purgeFailed } from "./errors";
import { purgeAccountFirestore, purgeHealthFirestore } from "./firestorePurge";
import {
  accountUserPrefix,
  deleteStoragePrefix,
  healthReportsPrefix,
} from "./storagePurge";

export interface PurgeResult {
  ok: true;
  mode: "health" | "account";
}

/**
 * Trusted purge for the authenticated caller only.
 * UID and paths are never accepted from the client.
 */
export async function runPurgeUserData(
  request: CallableRequest,
): Promise<PurgeResult> {
  const uid = requireAuthenticatedUid(request);
  requireRecentAuth(request);

  let mode: "health" | "account";
  try {
    mode = parsePurgeMode(request.data);
  } catch (error) {
    const code = error instanceof Error ? error.message : "INVALID_MODE";
    throw invalidArgument(code);
  }

  const started = Date.now();
  logger.info("purgeUserData.start", { uid, mode });

  const db = getFirestore();

  try {
    if (mode === "health") {
      await setDeletionGuard(db, uid, "health");
      await deleteStoragePrefix(healthReportsPrefix(uid));
      await purgeHealthFirestore(db, uid);
      await clearDeletionGuard(db, uid);
    } else {
      await setDeletionGuard(db, uid, "account");
      await deleteStoragePrefix(accountUserPrefix(uid));
      await purgeAccountFirestore(db, uid);
      // Root (and guard) are gone after recursive account delete.
    }

    logger.info("purgeUserData.ok", {
      uid,
      mode,
      durationMs: Date.now() - started,
    });
    return { ok: true, mode };
  } catch (error) {
    logger.error("purgeUserData.failed", {
      uid,
      mode,
      durationMs: Date.now() - started,
      // Operational only — never log error payloads that may contain content.
      errorName: error instanceof Error ? error.name : "unknown",
    });
    throw purgeFailed();
  }
}
