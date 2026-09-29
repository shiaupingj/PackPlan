import { test } from 'node:test';
import assert from 'node:assert/strict';
import ExcelJS from 'exceljs';
import { COLUMNS, buildDocsFromRows } from './gear_weights_csv.mjs';
import { readXlsxTable } from './gear_weights_xlsx.mjs';

// 分類分頁不含 category_id 欄
const SHEET_COLUMNS = COLUMNS.filter((c) => c !== 'category_id');

async function workbookBuffer(build) {
  const workbook = new ExcelJS.Workbook();
  build(workbook);
  return Buffer.from(await workbook.xlsx.writeBuffer());
}

async function readDocs(buffer) {
  const { rows, lineLabel } = await readXlsxTable(buffer);
  return buildDocsFromRows(rows, { lineLabel });
}

test('每個分頁是一個分類,分頁名稱帶入 categoryId;說明分頁不讀', async () => {
  const buffer = await workbookBuffer((workbook) => {
    workbook.addWorksheet('說明').addRow(['這頁不該被讀']);
    const sleep = workbook.addWorksheet('sleep');
    sleep.addRow(SHEET_COLUMNS);
    sleep.addRow(['sleeping-bag', '睡袋', null, null, null, 900, 700, 1500]);
    const tools = workbook.addWorksheet('hiking-tools');
    tools.addRow(SHEET_COLUMNS);
    tools.addRow([
      'headlamp',
      { richText: [{ text: '頭' }, { text: '燈' }] },
      null,
      null,
      null,
      { formula: '80+10', result: 90 },
    ]);
    workbook.addWorksheet('空白分頁');
  });

  const { docs, errors } = await readDocs(buffer);
  assert.deepEqual(errors, []);
  assert.equal(docs.get('sleeping-bag').categoryId, 'sleep');
  assert.equal(docs.get('sleeping-bag').weightMax, 1500);
  assert.equal(docs.get('headlamp').categoryId, 'hiking-tools');
  assert.equal(docs.get('headlamp').nameZh, '頭燈');
  assert.equal(docs.get('headlamp').weightGram, 90);
});

test('型號可以掛在其他分頁的通用項目下;key 跨分頁重複會被擋', async () => {
  const buffer = await workbookBuffer((workbook) => {
    const backpack = workbook.addWorksheet('backpack');
    backpack.addRow(SHEET_COLUMNS);
    backpack.addRow(['large-backpack', '大背包', null, null, null, 1500]);
    const luggage = workbook.addWorksheet('luggage');
    luggage.addRow(SHEET_COLUMNS);
    luggage.addRow(['osprey-exos-58', 'Osprey Exos 58', 'large-backpack', 'Osprey', null, 1200]);
    luggage.addRow(['large-backpack', '大背包', null, null, null, 1500]);
  });

  const { docs, errors } = await readDocs(buffer);
  assert.equal(docs.get('osprey-exos-58').parentKey, 'large-backpack');
  assert.deepEqual(errors, ['luggage 分頁第 3 行:item_key「large-backpack」重複']);
});

test('錯誤訊息指到分頁與 Excel 列號,空白列不影響列號', async () => {
  const buffer = await workbookBuffer((workbook) => {
    const cooking = workbook.addWorksheet('cooking');
    cooking.addRow(SHEET_COLUMNS);
    cooking.addRow(['cup', '杯子', null, null, null, 100]);
    cooking.addRow([]);
    cooking.addRow(['stove', '爐頭', null, null, null, 1.5]);
  });

  const { docs, errors } = await readDocs(buffer);
  assert.equal(docs.size, 1);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /^cooking 分頁第 4 行/);
});

test('分頁名稱不是 category_id 格式、或缺欄位時整份拒絕', async () => {
  const badName = await workbookBuffer((workbook) => {
    workbook.addWorksheet('Food').addRow(SHEET_COLUMNS);
  });
  await assert.rejects(readXlsxTable(badName), /分頁「Food」的名稱要是 category_id/);

  const missingColumn = await workbookBuffer((workbook) => {
    workbook.addWorksheet('food').addRow(['item_key', 'name_zh']);
  });
  await assert.rejects(readXlsxTable(missingColumn), /分頁「food」第 1 行缺少欄位:parent_key/);
});

test('舊版單一 gear_weights 分頁照 category_id 欄分類', async () => {
  const buffer = await workbookBuffer((workbook) => {
    const sheet = workbook.addWorksheet('gear_weights');
    sheet.addRow(COLUMNS);
    sheet.addRow(['sleeping-bag', '睡袋', null, null, null, 'sleep', 900]);
  });

  const { docs, errors } = await readDocs(buffer);
  assert.deepEqual(errors, []);
  assert.equal(docs.get('sleeping-bag').categoryId, 'sleep');
});
