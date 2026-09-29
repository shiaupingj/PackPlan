// 讀取 gear_weights.xlsx,把所有分類分頁合併成一張表(第一列為 COLUMNS)。
//
// 每個分頁是一個分類,分頁名稱就是 category_id(如 backpack、food、sleep),分頁裡不用 category_id 欄;
// 新增分類 = 新增一個分頁。「說明」分頁不讀,完全空白的分頁略過。
// 舊版單一「gear_weights」分頁(分類寫在 category_id 欄)仍可讀。
import readXlsxFile from 'read-excel-file/node';
import { COLUMNS } from './gear_weights_csv.mjs';

export const LEGACY_SHEET = 'gear_weights';
export const IGNORED_SHEETS = ['說明'];
const CATEGORY_PATTERN = /^[a-z0-9][a-z0-9-]*$/;

function cellText(value) {
  if (value == null) return '';
  if (value instanceof Date) return value.toISOString();
  return String(value);
}

// source:檔案路徑或 Buffer
// 回傳 { rows, lineLabel }:rows 交給 buildDocsFromRows,lineLabel 讓錯誤訊息指到「分頁 + Excel 列號」
export async function readXlsxTable(source) {
  const sheets = await readXlsxFile(source);
  const rows = [COLUMNS];
  const labels = [''];

  for (const { sheet: name, data } of sheets) {
    if (IGNORED_SHEETS.includes(name)) continue;
    const cells = data.map((row) => row.map(cellText));
    if (cells.every((row) => row.every((cell) => cell.trim() === ''))) continue;

    const legacy = name === LEGACY_SHEET;
    if (!legacy && !CATEGORY_PATTERN.test(name)) {
      throw new Error(`分頁「${name}」的名稱要是 category_id(小寫英數與 -,例如 backpack、food)`);
    }
    const header = cells[0].map((h) => h.trim());
    const missing = COLUMNS.filter(
      (c) => !header.includes(c) && (legacy || c !== 'category_id'),
    );
    if (missing.length > 0) {
      throw new Error(`分頁「${name}」第 1 行缺少欄位:${missing.join(', ')}`);
    }

    cells.slice(1).forEach((row, index) => {
      const blank = row.every((cell) => cell.trim() === '');
      rows.push(
        COLUMNS.map((column) => {
          if (column === 'category_id' && !legacy) return blank ? '' : name;
          return row[header.indexOf(column)] ?? '';
        }),
      );
      labels.push(`${name} 分頁第 ${index + 2} 行`);
    });
  }

  if (rows.length === 1) throw new Error('xlsx 裡沒有任何分類分頁');
  return { rows, lineLabel: (line) => labels[line - 1] };
}
