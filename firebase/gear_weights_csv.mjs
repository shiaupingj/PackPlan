// 把 gear_weights.csv 解析成 Firestore 文件。純函式,不碰網路,方便測試。
//
// 欄位:item_key,name_zh,aliases,category_id,weight_gram,weight_min,weight_max,note,is_active
// - item_key:文件 ID,對應 App 範本 key(小寫英數與 -)
// - aliases:以 | 分隔的別名,供自訂項目名稱比對
// - weight_gram 留空但有 min/max → 自動取中間值;三者皆空 → 視為待填,略過不上傳
// - is_active 留空視為 true;填 false/0/no 表示下架

export const COLUMNS = [
  'item_key',
  'name_zh',
  'aliases',
  'category_id',
  'weight_gram',
  'weight_min',
  'weight_max',
  'note',
  'is_active',
];

const KEY_PATTERN = /^[a-z0-9][a-z0-9-]*$/;

export function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;
  const src = text.replace(/^﻿/, '');

  for (let i = 0; i < src.length; i++) {
    const ch = src[i];
    if (inQuotes) {
      if (ch === '"') {
        if (src[i + 1] === '"') {
          field += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field += ch;
      }
    } else if (ch === '"') {
      inQuotes = true;
    } else if (ch === ',') {
      row.push(field);
      field = '';
    } else if (ch === '\n' || ch === '\r') {
      if (ch === '\r' && src[i + 1] === '\n') i++;
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
    } else {
      field += ch;
    }
  }
  if (field !== '' || row.length > 0) {
    row.push(field);
    rows.push(row);
  }
  return rows.filter((r) => r.some((cell) => cell.trim() !== ''));
}

function parseOptionalInt(raw, label, errors, line) {
  const value = raw.trim();
  if (value === '') return null;
  if (!/^\d+$/.test(value) || Number(value) <= 0) {
    errors.push(`第 ${line} 行:${label}「${value}」必須是正整數(公克)`);
    return null;
  }
  return Number(value);
}

function parseActive(raw) {
  const value = raw.trim().toLowerCase();
  return !['false', '0', 'no', 'n'].includes(value);
}

// 回傳 { docs: Map<itemKey, doc>, pending: string[], errors: string[] }
export function buildDocs(text) {
  const rows = parseCsv(text);
  const errors = [];
  const pending = [];
  const docs = new Map();

  if (rows.length === 0) {
    return { docs, pending, errors: ['CSV 是空的'] };
  }

  const header = rows[0].map((h) => h.trim());
  const missing = COLUMNS.filter((c) => !header.includes(c));
  if (missing.length > 0) {
    return { docs, pending, errors: [`缺少欄位:${missing.join(', ')}`] };
  }
  const col = Object.fromEntries(COLUMNS.map((c) => [c, header.indexOf(c)]));

  rows.slice(1).forEach((cells, index) => {
    const line = index + 2;
    const get = (name) => (cells[col[name]] ?? '').trim();

    const itemKey = get('item_key');
    const nameZh = get('name_zh');
    if (!KEY_PATTERN.test(itemKey)) {
      errors.push(`第 ${line} 行:item_key「${itemKey}」只能用小寫英數與 -`);
      return;
    }
    if (docs.has(itemKey)) {
      errors.push(`第 ${line} 行:item_key「${itemKey}」重複`);
      return;
    }
    if (nameZh === '') {
      errors.push(`第 ${line} 行:${itemKey} 缺 name_zh`);
      return;
    }

    const lineErrors = [];
    let weightGram = parseOptionalInt(get('weight_gram'), 'weight_gram', lineErrors, line);
    const weightMin = parseOptionalInt(get('weight_min'), 'weight_min', lineErrors, line);
    const weightMax = parseOptionalInt(get('weight_max'), 'weight_max', lineErrors, line);
    if (lineErrors.length > 0) {
      errors.push(...lineErrors);
      return;
    }
    if ((weightMin === null) !== (weightMax === null)) {
      errors.push(`第 ${line} 行:${itemKey} 的 weight_min / weight_max 要一起填`);
      return;
    }
    if (weightMin !== null && weightMin > weightMax) {
      errors.push(`第 ${line} 行:${itemKey} 的 weight_min 大於 weight_max`);
      return;
    }
    if (weightGram === null && weightMin !== null) {
      weightGram = Math.round((weightMin + weightMax) / 2);
    }
    if (weightGram === null) {
      pending.push(itemKey);
      return;
    }
    if (weightMin !== null && (weightGram < weightMin || weightGram > weightMax)) {
      errors.push(`第 ${line} 行:${itemKey} 的 weight_gram 不在範圍內`);
      return;
    }

    const aliases = get('aliases')
      .split('|')
      .map((a) => a.trim())
      .filter((a) => a !== '' && a !== nameZh);

    docs.set(itemKey, {
      nameZh,
      aliases: [...new Set(aliases)],
      categoryId: get('category_id') || null,
      weightGram,
      weightMin,
      weightMax,
      note: get('note') || null,
      isActive: parseActive(get('is_active')),
    });
  });

  return { docs, pending, errors };
}

const COMPARED_FIELDS = [
  'nameZh',
  'categoryId',
  'weightGram',
  'weightMin',
  'weightMax',
  'note',
  'isActive',
];

export function sameDoc(a, b) {
  if (!a || !b) return false;
  for (const field of COMPARED_FIELDS) {
    if ((a[field] ?? null) !== (b[field] ?? null)) return false;
  }
  const aa = a.aliases ?? [];
  const ba = b.aliases ?? [];
  return aa.length === ba.length && aa.every((v, i) => v === ba[i]);
}

// existing: Map<itemKey, doc>(目前 Firestore 內容)
// 回傳 { upserts: [[key, doc]], deactivations: [key] }
export function diffDocs(existing, next) {
  const upserts = [];
  for (const [key, doc] of next) {
    if (!sameDoc(existing.get(key), doc)) upserts.push([key, doc]);
  }
  const deactivations = [];
  for (const [key, doc] of existing) {
    if (!next.has(key) && doc.isActive !== false) deactivations.push(key);
  }
  return { upserts, deactivations };
}
