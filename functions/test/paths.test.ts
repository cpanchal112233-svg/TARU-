import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { HEALTH_COLLECTION_ROOTS } from "../src/firestorePurge";
import {
  accountUserPrefix,
  healthReportsPrefix,
} from "../src/storagePurge";

describe("purge path contracts", () => {
  it("uses the six health Firestore roots", () => {
    assert.deepEqual([...HEALTH_COLLECTION_ROOTS], [
      "health",
      "doseLogs",
      "habitLogs",
      "routine",
      "measurements",
      "reports",
    ]);
  });

  it("builds Storage prefixes from uid only", () => {
    assert.equal(healthReportsPrefix("abc"), "users/abc/reports/");
    assert.equal(accountUserPrefix("abc"), "users/abc/");
  });
});
