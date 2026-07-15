import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions/v2";
import {onDocumentWritten} from "firebase-functions/v2/firestore";

import {loadSyncConfig, mappingById} from "./config.js";
import {syncFirestoreWrite} from "./firestore-sync.js";
import {createSheetEditWebhook} from "./webhook.js";

initializeApp();
const config = loadSyncConfig();

setGlobalOptions({
  region: config.region,
  serviceAccount: config.runtimeServiceAccount,
  memory: "256MiB",
  timeoutSeconds: 120,
  maxInstances: 10,
});

function firestoreSync(mappingId: string) {
  const mapping = mappingById(config, mappingId);
  return onDocumentWritten(
    {
      document: mapping.firestorePattern,
      retry: true,
    },
    async (event) => syncFirestoreWrite(config, mapping, event as never),
  );
}

export const syncUsersToSheets = firestoreSync("users");
export const syncClassesToSheets = firestoreSync("classes");
export const syncTemplatesToSheets = firestoreSync("templates");
export const syncInvoicesToSheets = firestoreSync("invoices");
export const syncAllocationsToSheets = firestoreSync("allocations");
export const syncPendingOnboardingToSheets = firestoreSync("pendingOnboarding");
export const syncGlobalStateToSheets = firestoreSync("globalState");
export const syncClassArchivesToSheets = firestoreSync("classArchives");

export const sheetEditWebhook = createSheetEditWebhook(config);
