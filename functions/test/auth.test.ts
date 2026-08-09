import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  parsePurgeMode,
  RECENT_AUTH_WINDOW_SECONDS,
  requireRecentAuth,
} from "../src/auth";
import { recentAuthRequired } from "../src/errors";

function requestWithAuthTime(authTime: number | undefined) {
  return {
    auth: {
      uid: "user-a",
      token: authTime === undefined ? {} : { auth_time: authTime },
    },
    data: { mode: "health" },
    rawRequest: {} as never,
  } as never;
}

describe("parsePurgeMode", () => {
  it("accepts health and account", () => {
    assert.equal(parsePurgeMode({ mode: "health" }), "health");
    assert.equal(parsePurgeMode({ mode: "account" }), "account");
  });

  it("rejects missing/invalid mode", () => {
    assert.throws(() => parsePurgeMode({}), /INVALID_MODE/);
    assert.throws(() => parsePurgeMode({ mode: "all" }), /INVALID_MODE/);
  });

  it("rejects forbidden targeting fields", () => {
    assert.throws(
      () => parsePurgeMode({ mode: "health", uid: "other" }),
      /FORBIDDEN_FIELD/,
    );
    assert.throws(
      () => parsePurgeMode({ mode: "health", path: "users/x" }),
      /FORBIDDEN_FIELD/,
    );
  });
});

describe("requireRecentAuth", () => {
  it("accepts auth within the TARU window", () => {
    const now = 1_700_000_000_000;
    const authTime = now / 1000 - (RECENT_AUTH_WINDOW_SECONDS - 1);
    assert.doesNotThrow(() =>
      requireRecentAuth(requestWithAuthTime(authTime), now),
    );
  });

  it("rejects stale auth_time", () => {
    const now = 1_700_000_000_000;
    const authTime = now / 1000 - (RECENT_AUTH_WINDOW_SECONDS + 1);
    assert.throws(
      () => requireRecentAuth(requestWithAuthTime(authTime), now),
      (error: unknown) => {
        assert.ok(error instanceof Error);
        assert.equal(
          (error as { message?: string }).message,
          recentAuthRequired().message,
        );
        return true;
      },
    );
  });

  it("rejects missing auth_time", () => {
    assert.throws(() => requireRecentAuth(requestWithAuthTime(undefined)));
  });
});
