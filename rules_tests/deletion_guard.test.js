import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, it, before, after } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, setDoc, updateDoc, getDoc, deleteDoc } from "firebase/firestore";
import { ref, uploadBytes } from "firebase/storage";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "..");

let testEnv;

before(async () => {
  // Must match so Storage rules firestore.* lookups hit the same emulator DB.
  testEnv = await initializeTestEnvironment({
    projectId: "taru-673bb",
    firestore: {
      rules: readFileSync(join(root, "firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
    storage: {
      rules: readFileSync(join(root, "storage.rules"), "utf8"),
      host: "127.0.0.1",
      port: 9199,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

async function seedAccount(uid, extra = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `users/${uid}`), {
      name: "Temp",
      email: `${uid}@example.com`,
      createdAt: new Date().toISOString(),
      ...extra,
    });
  });
}

async function clearGuard(uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `users/${uid}`), {
      name: "Temp",
      email: `${uid}@example.com`,
      createdAt: new Date().toISOString(),
    });
  });
}

function pdfBytes() {
  return new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34]);
}

function textBytes(n = 16) {
  return new Uint8Array(n).fill(0x61);
}

describe("Firestore deletion guard", () => {
  it("allows owner child writes when deletion inactive", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertSucceeds(
      setDoc(doc(alice.firestore(), "users/alice/health/profile"), {
        heightCm: 170,
      }),
    );
    await assertSucceeds(
      setDoc(doc(alice.firestore(), "users/alice/supplements/s1"), {
        name: "Vitamin D",
        provenance: "selfReported",
      }),
    );
    await assertSucceeds(
      setDoc(doc(alice.firestore(), "users/alice/health/dietaryProfile"), {
        pattern: "vegetarian",
      }),
    );
  });

  it("denies other users writing health context collections", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const bob = testEnv.authenticatedContext("bob");
    await assertFails(
      setDoc(doc(bob.firestore(), "users/alice/familyHistory/f1"), {
        relationship: "Mother",
      }),
    );
  });

  it("denies owner child writes when deletionInProgress is health", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice", { deletionInProgress: "health" });
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      setDoc(doc(alice.firestore(), "users/alice/health/profile"), {
        heightCm: 171,
      }),
    );
    await assertFails(
      setDoc(doc(alice.firestore(), "users/alice/supplements/s1"), {
        name: "Vitamin D",
      }),
    );
    await assertFails(
      setDoc(doc(alice.firestore(), "users/alice/healthGoals/g1"), {
        title: "Walk more",
      }),
    );
  });

  it("denies client updates that set deletionInProgress", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      updateDoc(doc(alice.firestore(), "users/alice"), {
        deletionInProgress: "health",
      }),
    );
  });

  it("allows owner name update when deletion inactive", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertSucceeds(
      updateDoc(doc(alice.firestore(), "users/alice"), { name: "Alice" }),
    );
  });

  it("denies child writes when account root is missing", async () => {
    await testEnv.clearFirestore();
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      setDoc(doc(alice.firestore(), "users/alice/health/profile"), {
        heightCm: 170,
      }),
    );
  });

  it("denies other users", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const bob = testEnv.authenticatedContext("bob");
    await assertFails(getDoc(doc(bob.firestore(), "users/alice")));
  });

  it("allows owner root CREATE with identity fields only", async () => {
    await testEnv.clearFirestore();
    const alice = testEnv.authenticatedContext("alice");
    await assertSucceeds(
      setDoc(doc(alice.firestore(), "users/alice"), {
        name: "Alice",
        email: "alice@example.com",
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it("denies owner root CREATE with deletionInProgress", async () => {
    await testEnv.clearFirestore();
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      setDoc(doc(alice.firestore(), "users/alice"), {
        name: "Alice",
        email: "alice@example.com",
        createdAt: new Date().toISOString(),
        deletionInProgress: "health",
      }),
    );
  });

  it("denies owner root CREATE with deletionStartedAt", async () => {
    await testEnv.clearFirestore();
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      setDoc(doc(alice.firestore(), "users/alice"), {
        name: "Alice",
        email: "alice@example.com",
        createdAt: new Date().toISOString(),
        deletionStartedAt: new Date().toISOString(),
      }),
    );
  });

  it("denies unauthenticated root CREATE", async () => {
    await testEnv.clearFirestore();
    const anon = testEnv.unauthenticatedContext();
    await assertFails(
      setDoc(doc(anon.firestore(), "users/alice"), {
        name: "Alice",
        email: "alice@example.com",
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it("denies other user root CREATE for another uid", async () => {
    await testEnv.clearFirestore();
    const bob = testEnv.authenticatedContext("bob");
    await assertFails(
      setDoc(doc(bob.firestore(), "users/alice"), {
        name: "Alice",
        email: "alice@example.com",
        createdAt: new Date().toISOString(),
      }),
    );
  });
});

describe("Storage deletion guard (Firestore account root)", () => {
  it("1 owner source PDF ALLOW", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertSucceeds(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/file.pdf"),
        pdfBytes(),
        { contentType: "application/pdf" },
      ),
    );
  });

  it("2 owner source image ALLOW", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertSucceeds(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/photo.jpg"),
        new Uint8Array([0xff, 0xd8, 0xff]),
        { contentType: "image/jpeg" },
      ),
    );
  });

  it("3 owner source text DENY", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/file.txt"),
        textBytes(),
        { contentType: "text/plain" },
      ),
    );
  });

  it("4 owner derived text <=256KiB ALLOW", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertSucceeds(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/derived/extracted.txt"),
        textBytes(32),
        { contentType: "text/plain" },
      ),
    );
  });

  it("5 owner derived PDF DENY", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/derived/extracted.txt"),
        pdfBytes(),
        { contentType: "application/pdf" },
      ),
    );
  });

  it("5b owner derived text >256KiB DENY", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    // Phase 9 boundary: derived text/plain must be <= 256 KiB.
    await assertFails(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/derived/extracted.txt"),
        textBytes(256 * 1024 + 1),
        { contentType: "text/plain" },
      ),
    );
  });

  it("6 other user DENY", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const bob = testEnv.authenticatedContext("bob");
    await assertFails(
      uploadBytes(
        ref(bob.storage(), "users/alice/reports/r1/file.pdf"),
        pdfBytes(),
        { contentType: "application/pdf" },
      ),
    );
  });

  it("7 unauth DENY", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const anon = testEnv.unauthenticatedContext();
    await assertFails(
      uploadBytes(
        ref(anon.storage(), "users/alice/reports/r1/file.pdf"),
        pdfBytes(),
        { contentType: "application/pdf" },
      ),
    );
  });

  it("8 health guard source DENY", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice", { deletionInProgress: "health" });
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/file.pdf"),
        pdfBytes(),
        { contentType: "application/pdf" },
      ),
    );
  });

  it("9 health guard derived DENY", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice", { deletionInProgress: "health" });
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/derived/extracted.txt"),
        textBytes(),
        { contentType: "text/plain" },
      ),
    );
  });

  it("10 account guard source DENY", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice", { deletionInProgress: "account" });
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/file.pdf"),
        pdfBytes(),
        { contentType: "application/pdf" },
      ),
    );
  });

  it("11 account guard derived DENY", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice", { deletionInProgress: "account" });
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/derived/extracted.txt"),
        textBytes(),
        { contentType: "text/plain" },
      ),
    );
  });

  it("12 missing root source DENY", async () => {
    await testEnv.clearFirestore();
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/file.pdf"),
        pdfBytes(),
        { contentType: "application/pdf" },
      ),
    );
  });

  it("13 missing root derived DENY", async () => {
    await testEnv.clearFirestore();
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/derived/extracted.txt"),
        textBytes(),
        { contentType: "text/plain" },
      ),
    );
  });

  it("14 after health guard cleared source ALLOW", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice", { deletionInProgress: "health" });
    await clearGuard("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertSucceeds(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/file.pdf"),
        pdfBytes(),
        { contentType: "application/pdf" },
      ),
    );
  });

  it("15 after health guard cleared derived ALLOW", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice", { deletionInProgress: "health" });
    await clearGuard("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertSucceeds(
      uploadBytes(
        ref(alice.storage(), "users/alice/reports/r1/derived/extracted.txt"),
        textBytes(),
        { contentType: "text/plain" },
      ),
    );
  });
});

const healthContextPaths = [
  "users/alice/health/dietaryProfile",
  "users/alice/health/lifestyle",
  "users/alice/supplements/s1",
  "users/alice/familyHistory/f1",
  "users/alice/procedures/p1",
  "users/alice/immunizations/i1",
  "users/alice/healthGoals/g1",
  "users/alice/careTeam/c1",
];

const healthContextPayload = {
  name: "Example",
  title: "Example",
  vaccine: "Tetanus",
  relationship: "Mother",
  condition: "Example",
  pattern: "vegetarian",
  provenance: "selfReported",
};

describe("Health Context Firestore path matrix", () => {
  for (const path of healthContextPaths) {
    it(`owner can read ${path} when healthy`, async () => {
      await testEnv.clearFirestore();
      await seedAccount("alice");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), path), healthContextPayload);
      });
      const alice = testEnv.authenticatedContext("alice");
      await assertSucceeds(getDoc(doc(alice.firestore(), path)));
    });

    it(`owner can write ${path} when healthy`, async () => {
      await testEnv.clearFirestore();
      await seedAccount("alice");
      const alice = testEnv.authenticatedContext("alice");
      await assertSucceeds(
        setDoc(doc(alice.firestore(), path), healthContextPayload),
      );
    });

    it(`owner can delete ${path} when healthy`, async () => {
      await testEnv.clearFirestore();
      await seedAccount("alice");
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), path), healthContextPayload);
      });
      const alice = testEnv.authenticatedContext("alice");
      await assertSucceeds(deleteDoc(doc(alice.firestore(), path)));
    });

    it(`cross-user is denied ${path}`, async () => {
      await testEnv.clearFirestore();
      await seedAccount("alice");
      await seedAccount("bob");
      const bob = testEnv.authenticatedContext("bob");
      await assertFails(getDoc(doc(bob.firestore(), path)));
      await assertFails(
        setDoc(doc(bob.firestore(), path), healthContextPayload),
      );
    });

    it(`health deletion guard denies write ${path}`, async () => {
      await testEnv.clearFirestore();
      await seedAccount("alice", { deletionInProgress: "health" });
      const alice = testEnv.authenticatedContext("alice");
      await assertFails(
        setDoc(doc(alice.firestore(), path), healthContextPayload),
      );
    });

    it(`account deletion guard denies write ${path}`, async () => {
      await testEnv.clearFirestore();
      await seedAccount("alice", { deletionInProgress: "account" });
      const alice = testEnv.authenticatedContext("alice");
      await assertFails(
        setDoc(doc(alice.firestore(), path), healthContextPayload),
      );
    });

    it(`missing account root denies write ${path}`, async () => {
      await testEnv.clearFirestore();
      const alice = testEnv.authenticatedContext("alice");
      await assertFails(
        setDoc(doc(alice.firestore(), path), healthContextPayload),
      );
    });
  }

  it("clients cannot mutate root deletion guard fields", async () => {
    await testEnv.clearFirestore();
    await seedAccount("alice");
    const alice = testEnv.authenticatedContext("alice");
    await assertFails(
      updateDoc(doc(alice.firestore(), "users/alice"), {
        deletionInProgress: "health",
      }),
    );
    await assertFails(
      updateDoc(doc(alice.firestore(), "users/alice"), {
        deletionInProgress: "account",
      }),
    );
  });
});
