// 讀取 gear_weights.xlsx 的「gear_weights」分頁(沒有就用第一個分頁),轉成字串二維陣列。
import readXlsxFile from 'read-excel-file/node';

export const SHEET_NAME = 'gear_weights';

function cellText(value) {
  if (value == null) return '';
  if (value instanceof Date) return value.toISOString();
  return String(value);
}

// source:檔案路徑或 Buffer
export async function readXlsxRows(source) {
  const sheets = await readXlsxFile(source);
  const sheet = sheets.find((s) => s.sheet === SHEET_NAME) ?? sheets[0];
  if (!sheet) throw new Error('xlsx 裡沒有任何分頁');
  return sheet.data.map((row) => row.map(cellText));
}
