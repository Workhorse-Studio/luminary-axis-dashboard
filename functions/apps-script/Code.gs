const DEFAULT_SYNC_ENDPOINT = "https://sheeteditwebhook-7qvxore2ga-as.a.run.app";
const MANAGED_SHEETS = new Set([
  "users",
  "classes",
  "templates",
  "global_state_invoices",
  "global_state_allocations",
  "global_state_pendingOnboarding",
  "global_state",
  "classes_archives",
]);
const READ_ONLY_HEADERS = new Set([
  "docId",
  "parentId",
  "_version",
  "_fieldHashes",
  "_syncStatus",
]);

/** Adds setup to the bound spreadsheet UI, where prompts are supported. */
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu("Axis Sync")
    .addItem("Set up sync", "setupSheetSync")
    .addToUi();
}

/** Run from Axis Sync > Set up sync as the trigger-owner account. */
function setupSheetSync() {
  const ui = SpreadsheetApp.getUi();
  const endpointPrompt = ui.prompt(
    "Sheet sync endpoint",
    "Paste the deployed sheetEditWebhook URL.",
    ui.ButtonSet.OK_CANCEL,
  );
  if (endpointPrompt.getSelectedButton() !== ui.Button.OK) return;
  const endpoint = endpointPrompt.getResponseText().trim() || DEFAULT_SYNC_ENDPOINT;
  if (!endpoint) throw new Error("The webhook endpoint is required.");

  const secretPrompt = ui.prompt(
    "Sheet sync secret",
    "Paste the SHEET_SYNC_WEBHOOK_SECRET value.",
    ui.ButtonSet.OK_CANCEL,
  );
  if (secretPrompt.getSelectedButton() !== ui.Button.OK) return;
  const secret = secretPrompt.getResponseText().trim();
  if (!secret) throw new Error("The webhook secret is required.");

  const spreadsheet = SpreadsheetApp.getActive();
  PropertiesService.getScriptProperties().setProperties({
    SHEET_SYNC_ENDPOINT: endpoint,
    SHEET_SYNC_SECRET: secret,
    SHEET_SYNC_SPREADSHEET_ID: spreadsheet.getId(),
  });

  for (const trigger of ScriptApp.getProjectTriggers()) {
    if (trigger.getHandlerFunction() === "handleSheetEdit") {
      ScriptApp.deleteTrigger(trigger);
    }
  }
  ScriptApp.newTrigger("handleSheetEdit").forSpreadsheet(spreadsheet).onEdit().create();
  ui.alert("Firestore sync is installed for this spreadsheet.");
}

/** Installable onEdit handler. Script/API writes do not recursively trigger it. */
function handleSheetEdit(event) {
  if (!event || !event.range) return;
  const sheet = event.range.getSheet();
  if (!MANAGED_SHEETS.has(sheet.getName()) || event.range.getRow() === 1) return;

  const lock = LockService.getDocumentLock();
  lock.waitLock(30000);
  try {
    forwardSheetEdit_(event, sheet);
  } finally {
    lock.releaseLock();
  }
}

function forwardSheetEdit_(event, sheet) {
  const properties = PropertiesService.getScriptProperties();
  const endpoint = properties.getProperty("SHEET_SYNC_ENDPOINT");
  const secret = properties.getProperty("SHEET_SYNC_SECRET");
  const spreadsheetId = properties.getProperty("SHEET_SYNC_SPREADSHEET_ID");
  if (!endpoint || !secret || !spreadsheetId) {
    throw new Error("Run setupSheetSync before editing managed sheets.");
  }

  const lastColumn = sheet.getLastColumn();
  const headers = sheet.getRange(1, 1, 1, lastColumn).getValues()[0].map(String);
  const changedHeaders = [];
  for (let column = event.range.getColumn(); column <= event.range.getLastColumn(); column += 1) {
    const header = headers[column - 1];
    if (header && (!READ_ONLY_HEADERS.has(header) || header === "_delete")) {
      changedHeaders.push(header);
    }
  }
  if (changedHeaders.length === 0) return;

  const docIdIndex = headers.indexOf("docId");
  const parentIdIndex = headers.indexOf("parentId");
  const versionIndex = headers.indexOf("_version");
  const hashesIndex = headers.indexOf("_fieldHashes");
  const deleteIndex = headers.indexOf("_delete");
  const statusIndex = headers.indexOf("_syncStatus");
  if (docIdIndex < 0 || statusIndex < 0) throw new Error("Managed headers are missing.");

  const rows = [];
  for (let rowNumber = event.range.getRow(); rowNumber <= event.range.getLastRow(); rowNumber += 1) {
    let values = sheet.getRange(rowNumber, 1, 1, lastColumn).getValues()[0];
    const hasContent = values.some((value, index) => {
      const header = headers[index];
      return !header.startsWith("_") && value !== "";
    });
    if (!hasContent && !values[docIdIndex]) continue;

    if (!values[docIdIndex]) {
      const generatedId = Utilities.getUuid().replace(/-/g, "").slice(0, 20);
      sheet.getRange(rowNumber, docIdIndex + 1).setValue(generatedId);
      values = sheet.getRange(rowNumber, 1, 1, lastColumn).getValues()[0];
    }
    sheet.getRange(rowNumber, statusIndex + 1).setValue("SYNCING");
    rows.push({
      rowNumber,
      docId: String(values[docIdIndex] || ""),
      parentId: parentIdIndex >= 0 ? String(values[parentIdIndex] || "") : undefined,
      version: versionIndex >= 0 ? String(values[versionIndex] || "") : undefined,
      fieldHashes: hashesIndex >= 0 ? String(values[hashesIndex] || "") : undefined,
      deleteRequested: deleteIndex >= 0 && isTrue_(values[deleteIndex]),
      changedHeaders,
      values: Object.fromEntries(headers.map((header, index) => [header, values[index]])),
    });
  }
  if (rows.length === 0) return;

  const payload = {
    eventId: Utilities.getUuid(),
    timestamp: Date.now(),
    spreadsheetId,
    sheetTitle: sheet.getName(),
    rows,
  };
  const body = JSON.stringify(payload);
  const response = UrlFetchApp.fetch(endpoint, {
    method: "post",
    contentType: "application/json",
    payload: body,
    headers: {"X-Sheet-Sync-Signature": hmacHex_(body, secret)},
    muteHttpExceptions: true,
  });
  const responseBody = response.getContentText();
  if (response.getResponseCode() < 200 || response.getResponseCode() >= 300) {
    for (const row of rows) {
      sheet.getRange(row.rowNumber, statusIndex + 1).setValue(`ERROR: ${responseBody.slice(0, 300)}`);
    }
    throw new Error(`Sheet sync failed (${response.getResponseCode()}): ${responseBody}`);
  }

  const decoded = JSON.parse(responseBody);
  for (const result of decoded.results || []) {
    if (result.docId) sheet.getRange(result.rowNumber, docIdIndex + 1).setValue(result.docId);
    sheet.getRange(result.rowNumber, statusIndex + 1).setValue(result.status || "OK");
  }
}

function isTrue_(value) {
  return value === true || String(value).toLowerCase() === "true";
}

function hmacHex_(body, secret) {
  return Utilities.computeHmacSha256Signature(body, secret)
    .map((byte) => {
      const unsigned = byte < 0 ? byte + 256 : byte;
      return (`0${unsigned.toString(16)}`).slice(-2);
    })
    .join("");
}
