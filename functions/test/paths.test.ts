import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { HEALTH_COLLECTION_ROOTS } from "../src/firestorePurge";
import healthCollectionRoots from "../src/health_collection_roots.json";
import {
  accountUserPrefix,
  healthReportsPrefix,
} from "../src/storagePurge";

const expectedRoots = [
  "health",
  "doseLogs",
  "habitLogs",
  "routine",
  "measurements",
  "reports",
  "supplements",
  "familyHistory",
  "procedures",
  "immunizations",
  "healthGoals",
  "careTeam",
];

describe("purge path contracts", () => {
  it("uses the shared health Firestore roots manifest", () => {
    assert.deepEqual([...HEALTH_COLLECTION_ROOTS], expectedRoots);
    assert.deepEqual(healthCollectionRoots, expectedRoots);
  });

  it("builds Storage prefixes from uid only", () => {
    assert.equal(healthReportsPrefix("abc"), "users/abc/reports/");
    assert.equal(accountUserPrefix("abc"), "users/abc/");
  });
});
