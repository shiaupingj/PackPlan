import { test } from 'node:test';
import assert from 'node:assert/strict';
import ExcelJS from 'exceljs';
import { COLUMNS, buildDocsFromRows } from './gear_weights_csv.mjs';
import { readXlsxRows } from './gear_weights_xlsx.mjs';

async function workbookBuffer(build) {
  const workbook = new ExcelJS.Workbook();
  build(workbook);
  return Buffer.from(await workbook.xlsx.writeBuffer());
}

test('讀 gear_weights 分頁,數字、公式、rich text 都轉成字串', async () => {
  const buffer = await workbookBuffer((workbook) => {
    workbook.addWorksheet('說明').addRow(['這頁不該被讀']);
    const sheet = workbook.addWorksheet('gear_weights');
    sheet.addRow(COLUMNS);
    sheet.addRow(['sleeping-bag', '睡袋', null, null, null, 'sleep', 900, 700, 1500]);
    sheet.addRow([
      'headlamp',
      { richText: [{ text: '頭' }, { text: '燈' }] },
      null,
      null,
      null,
      null,
      { formula: '80+10', result: 90 },
    ]);
  });

  const rows = await readXlsxRows(buffer);
  assert.deepEqual(rows[0], COLUMNS);

  const { docs, errors } = buildDocsFromRows(rows);
  assert.deepEqual(errors, []);
  assert.equal(docs.get('sleeping-bag').weightGram, 900);
  assert.equal(docs.get('sleeping-bag').weightMax, 1500);
  assert.equal(docs.get('headlamp').nameZh, '頭燈');
  assert.equal(docs.get('headlamp').weightGram, 90);
});

test('空白列不影響錯誤訊息的列號,小數重量會被擋下', async () => {
  const buffer = await workbookBuffer((workbook) => {
    const sheet = workbook.addWorksheet('gear_weights');
    sheet.addRow(COLUMNS);
    sheet.addRow(['cup', '杯子', null, null, null, null, 100]);
    sheet.addRow([]);
    sheet.addRow(['stove', '爐頭', null, null, null, null, 1.5]);
  });

  const { docs, errors } = buildDocsFromRows(await readXlsxRows(buffer));
  assert.equal(docs.size, 1);
  assert.equal(errors.length, 1);
  assert.match(errors[0], /^第 4 行/);
});
