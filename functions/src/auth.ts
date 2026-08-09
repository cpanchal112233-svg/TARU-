import { CallableRequest } from "firebase-functions/v2/https";

import { recentAuthRequired, unauthenticated } from "./errors";

/** TARU destructive-operation window (seconds). Not a Firebase-platform constant. */
export const RECENT_AUTH_WINDOW_SECONDS = 300;

export type PurgeMode = "health" | "account";

export function requireAuthenticatedUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw unauthenticated();
  }
  return uid;
}

/**
 * Enforces recent authentication using the verified ID token auth_time claim.
 * Callers must reauthenticateWithCredential then force-refresh the ID token
 * before invoking purgeUserData.
 */
export function requireRecentAuth(request: CallableRequest, nowMs = Date.now()): void {
  const authTime = request.auth?.token?.auth_time;
  if (typeof authTime !== "number" || !Number.isFinite(authTime) || authTime <= 0) {
    throw recentAuthRequired();
  }

  const ageSeconds = nowMs / 1000 - authTime;
  if (ageSeconds < 0 || ageSeconds > RECENT_AUTH_WINDOW_SECONDS) {
    throw recentAuthRequired();
  }
}

export function parsePurgeMode(data: unknown): PurgeMode {
  if (data === null || typeof data !== "object" || Array.isArray(data)) {
    throw new Error("INVALID_MODE");
  }
  const mode = (data as { mode?: unknown }).mode;
  if (mode !== "health" && mode !== "account") {
    throw new Error("INVALID_MODE");
  }

  // Reject any attempt to pass targeting fields.
  const forbidden = [
    "uid",
    "userId",
    "path",
    "prefix",
    "collection",
    "bucket",
    "storagePath",
  ];
  for (const key of forbidden) {
    if (Object.prototype.hasOwnProperty.call(data, key)) {
      throw new Error("FORBIDDEN_FIELD");
    }
  }

  return mode;
}
