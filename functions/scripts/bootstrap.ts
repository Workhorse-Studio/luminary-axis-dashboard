import {applicationDefault, initializeApp} from "firebase-admin/app";

import {loadSyncConfig} from "../src/config.js";
import {loadAllManagedDocuments} from "../src/firestore-sync.js";
import {withSheetWriteLease} from "../src/lease.js";
import {SheetsStore} from "../src/sheets.js";

async function main(): Promise<void> {
  if (!process.argv.includes("--confirm-destroy-sheet-data")) {
    throw new Error(
      "Refusing to rebuild Sheets without --confirm-destroy-sheet-data",
    );
  }
  const config = loadSyncConfig();
  initializeApp({credential: applicationDefault(), projectId: config.projectId});
  const documents = await loadAllManagedDocuments(config);
  for (const mapping of config.managedSheets) {
    console.log(`${mapping.title}: ${documents.get(mapping.id)?.length ?? 0} Firestore document(s)`);
  }
  await withSheetWriteLease(async () => {
    await new SheetsStore(config).rebuildManagedSheets(documents);
  });
  console.log("Managed Google Sheet tabs rebuilt from Firestore.");
}

main().catch((error) => {
  console.error(error instanceof Error ? error.stack : error);
  process.exitCode = 1;
});
