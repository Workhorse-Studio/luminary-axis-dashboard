import {google, sheets_v4} from "googleapis";

import {buildHeaders, buildRow, columnName, findUpsertRow, quoteSheetTitle} from "./rows.js";
import type {ManagedDocument, ManagedSheetConfig, SyncConfig} from "./types.js";

const MIN_ROW_COUNT = 1000;

export class SheetsStore {
  private readonly api: sheets_v4.Sheets;

  constructor(private readonly config: SyncConfig) {
    const auth = new google.auth.GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/spreadsheets"],
    });
    this.api = google.sheets({version: "v4", auth});
  }

  async rebuildManagedSheets(
    documentsByMapping: Map<string, ManagedDocument[]>,
  ): Promise<void> {
    const spreadsheetId = this.config.spreadsheetId;
    const temporaryTitle = `_sync_bootstrap_${Date.now()}`;
    const temporary = await this.api.spreadsheets.batchUpdate({
      spreadsheetId,
      requestBody: {requests: [{addSheet: {properties: {title: temporaryTitle}}}]},
    });
    const temporaryId = temporary.data.replies?.[0]?.addSheet?.properties?.sheetId;

    try {
      const metadata = await this.api.spreadsheets.get({spreadsheetId});
      const managedTitles = new Set(this.config.managedSheets.map((sheet) => sheet.title));
      const deleteRequests = (metadata.data.sheets ?? [])
        .filter((sheet) => managedTitles.has(sheet.properties?.title ?? ""))
        .map((sheet) => ({deleteSheet: {sheetId: sheet.properties?.sheetId}}));
      if (deleteRequests.length > 0) {
        await this.api.spreadsheets.batchUpdate({
          spreadsheetId,
          requestBody: {requests: deleteRequests},
        });
      }

      for (const mapping of this.config.managedSheets) {
        const documents = documentsByMapping.get(mapping.id) ?? [];
        await this.createManagedSheet(mapping, documents);
      }
    } finally {
      if (temporaryId !== undefined && temporaryId !== null) {
        await this.api.spreadsheets.batchUpdate({
          spreadsheetId,
          requestBody: {requests: [{deleteSheet: {sheetId: temporaryId}}]},
        });
      }
    }
  }

  private async createManagedSheet(
    mapping: ManagedSheetConfig,
    documents: ManagedDocument[],
  ): Promise<void> {
    const headers = buildHeaders(documents, mapping.parentId);
    const rows = [headers, ...documents.map((document) => buildRow(headers, document))];
    const rowCount = Math.max(MIN_ROW_COUNT, rows.length + 100);
    const columnCount = Math.max(headers.length, 10);
    const response = await this.api.spreadsheets.batchUpdate({
      spreadsheetId: this.config.spreadsheetId,
      requestBody: {
        requests: [{
          addSheet: {
            properties: {
              title: mapping.title,
              gridProperties: {rowCount, columnCount, frozenRowCount: 1},
            },
          },
        }],
      },
    });
    const sheetId = response.data.replies?.[0]?.addSheet?.properties?.sheetId;
    if (sheetId === undefined || sheetId === null) {
      throw new Error(`Google Sheets did not return an ID for ${mapping.title}`);
    }

    await this.api.spreadsheets.values.update({
      spreadsheetId: this.config.spreadsheetId,
      range: `${quoteSheetTitle(mapping.title)}!A1`,
      valueInputOption: "RAW",
      requestBody: {values: rows},
    });

    const deleteColumn = headers.indexOf("_delete");
    const versionColumn = headers.indexOf("_version");
    const hashesColumn = headers.indexOf("_fieldHashes");
    const protectedColumns = [
      headers.indexOf("docId"),
      headers.indexOf("parentId"),
      versionColumn,
      hashesColumn,
      headers.indexOf("_syncStatus"),
    ].filter((index) => index >= 0);

    const requests: sheets_v4.Schema$Request[] = [
      {
        repeatCell: {
          range: {sheetId, startRowIndex: 0, endRowIndex: 1, startColumnIndex: 0, endColumnIndex: headers.length},
          cell: {
            userEnteredFormat: {
              backgroundColor: {red: 0.12, green: 0.20, blue: 0.32},
              textFormat: {bold: true, foregroundColor: {red: 1, green: 1, blue: 1}},
            },
          },
          fields: "userEnteredFormat(backgroundColor,textFormat)",
        },
      },
      {
        setDataValidation: {
          range: {sheetId, startRowIndex: 1, endRowIndex: rowCount, startColumnIndex: deleteColumn, endColumnIndex: deleteColumn + 1},
          rule: {condition: {type: "BOOLEAN"}, strict: true, showCustomUi: true},
        },
      },
      {
        addFilterView: {
          filter: {
            title: "Active records",
            range: {sheetId, startRowIndex: 0, endRowIndex: rowCount, startColumnIndex: 0, endColumnIndex: headers.length},
            criteria: {[String(deleteColumn)]: {hiddenValues: ["TRUE"]}},
          },
        },
      },
      {
        autoResizeDimensions: {
          dimensions: {sheetId, dimension: "COLUMNS", startIndex: 0, endIndex: headers.length},
        },
      },
      {
        updateDimensionProperties: {
          range: {sheetId, dimension: "COLUMNS", startIndex: versionColumn, endIndex: versionColumn + 1},
          properties: {hiddenByUser: true},
          fields: "hiddenByUser",
        },
      },
      {
        updateDimensionProperties: {
          range: {sheetId, dimension: "COLUMNS", startIndex: hashesColumn, endIndex: hashesColumn + 1},
          properties: {hiddenByUser: true},
          fields: "hiddenByUser",
        },
      },
      ...protectedColumns.map((column) => ({
        addProtectedRange: {
          protectedRange: {
            range: {sheetId, startColumnIndex: column, endColumnIndex: column + 1},
            description: `Managed by Firestore sync: ${headers[column]}`,
            warningOnly: false,
            editors: {
              users: [this.config.sheetOwnerEmail, this.config.runtimeServiceAccount],
            },
          },
        },
      })),
    ];

    await this.api.spreadsheets.batchUpdate({
      spreadsheetId: this.config.spreadsheetId,
      requestBody: {requests},
    });
  }

  async upsertDocument(
    mapping: ManagedSheetConfig,
    document: ManagedDocument,
  ): Promise<void> {
    const {headers, rows} = await this.readTable(mapping.title);
    const missingFields = Object.keys(document.data).filter((field) => !headers.includes(field));
    if (missingFields.length > 0) {
      for (const field of missingFields.sort()) headers.push(field);
      await this.ensureGridCapacity(mapping.title, 2, headers.length);
      await this.api.spreadsheets.values.update({
        spreadsheetId: this.config.spreadsheetId,
        range: `${quoteSheetTitle(mapping.title)}!A1`,
        valueInputOption: "RAW",
        requestBody: {values: [headers]},
      });
    }

    const rowNumber = findUpsertRow(
      headers,
      rows,
      document.id,
      mapping.parentId ? document.parentId : undefined,
    );
    await this.ensureGridCapacity(mapping.title, rowNumber, headers.length);
    const row = buildRow(headers, document);
    await this.api.spreadsheets.values.update({
      spreadsheetId: this.config.spreadsheetId,
      range: `${quoteSheetTitle(mapping.title)}!A${rowNumber}:${columnName(headers.length - 1)}${rowNumber}`,
      valueInputOption: "RAW",
      requestBody: {values: [row]},
    });
  }

  private async ensureGridCapacity(
    title: string,
    requiredRows: number,
    requiredColumns: number,
  ): Promise<void> {
    const response = await this.api.spreadsheets.get({
      spreadsheetId: this.config.spreadsheetId,
      fields: "sheets(properties(sheetId,title,gridProperties(rowCount,columnCount)))",
    });
    const properties = response.data.sheets
      ?.find((sheet) => sheet.properties?.title === title)
      ?.properties;
    if (properties?.sheetId === undefined || properties.sheetId === null) {
      throw new Error(`Managed sheet ${title} does not exist`);
    }
    const currentRows = properties.gridProperties?.rowCount ?? 0;
    const currentColumns = properties.gridProperties?.columnCount ?? 0;
    if (requiredRows <= currentRows && requiredColumns <= currentColumns) return;
    await this.api.spreadsheets.batchUpdate({
      spreadsheetId: this.config.spreadsheetId,
      requestBody: {
        requests: [{
          updateSheetProperties: {
            properties: {
              sheetId: properties.sheetId,
              gridProperties: {
                rowCount: Math.max(requiredRows + 100, currentRows),
                columnCount: Math.max(requiredColumns, currentColumns),
              },
            },
            fields: "gridProperties(rowCount,columnCount)",
          },
        }],
      },
    });
  }

  private async readTable(title: string): Promise<{
    headers: string[];
    rows: unknown[][];
  }> {
    const response = await this.api.spreadsheets.values.get({
      spreadsheetId: this.config.spreadsheetId,
      range: `${quoteSheetTitle(title)}!A:ZZ`,
      valueRenderOption: "UNFORMATTED_VALUE",
    });
    const rows = response.data.values ?? [];
    if (rows.length === 0) throw new Error(`Managed sheet ${title} has no header row`);
    return {headers: rows[0].map(String), rows};
  }
}
