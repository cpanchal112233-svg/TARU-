import { HttpsError } from "firebase-functions/v2/https";

/** Stable client-facing codes for purgeUserData. */
export type PurgeClientCode =
  | "UNAUTHENTICATED"
  | "RECENT_AUTH_REQUIRED"
  | "INVALID_ARGUMENT"
  | "PURGE_FAILED"
  | "PURGE_RETRY_REQUIRED";

export function unauthenticated(): HttpsError {
  return new HttpsError("unauthenticated", "UNAUTHENTICATED");
}

export function recentAuthRequired(): HttpsError {
  return new HttpsError("failed-precondition", "RECENT_AUTH_REQUIRED");
}

export function invalidArgument(detail: string): HttpsError {
  return new HttpsError("invalid-argument", `INVALID_ARGUMENT:${detail}`);
}

export function purgeFailed(detail?: string): HttpsError {
  // Message stays operational — never include PHI or report text.
  return new HttpsError(
    "internal",
    detail ? `PURGE_FAILED:${detail}` : "PURGE_FAILED",
  );
}

export function purgeRetryRequired(): HttpsError {
  return new HttpsError("unavailable", "PURGE_RETRY_REQUIRED");
}
