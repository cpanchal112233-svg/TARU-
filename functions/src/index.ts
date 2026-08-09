import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";
import { onCall } from "firebase-functions/v2/https";

import { runPurgeUserData } from "./purgeUserData";

initializeApp();

// Align with Firestore location (europe-west2). Storage Admin API is
// cross-region; recursive Firestore delete is the denser operational target.
setGlobalOptions({
  region: "europe-west2",
  timeoutSeconds: 540,
  memory: "1GiB",
});

export const purgeUserData = onCall(async (request) => {
  return runPurgeUserData(request);
});
