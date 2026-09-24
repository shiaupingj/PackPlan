import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildDocs, diffDocs, parseCsv } from './gear_weights_csv.mjs';

const HEADER =
  'item_key,name_zh,aliases,category_id,weight_gram,weight_min,weight_max,note,is_active';

test('parseCsv 處理 BOM、引號與逗號', () => {
  const rows = parseCsv('﻿a,b\r\n"x, y","say ""hi"""\n');
  assert.deepEqual(rows, [
    ['a', 'b'],
    ['x, y', 'say "hi"'],
  ]);
});

test('只填範圍時取中間值,別名去重並排除本名', () => {
  const { docs, errors } = buildDocs(
    `${HEADER}\nsleeping-bag,睡袋,睡袋|羽絨睡袋|羽絨睡袋,sleep,,700,1500,,\n`,
  );
  assert.deepEqual(errors, []);
  const doc = docs.get('sleeping-bag');
  assert.equal(doc.weightGram, 1100);
  assert.deepEqual(doc.aliases, ['羽絨睡袋']);
  assert.equal(doc.isActive, true);
});

test('沒填重量的列視為待填', () => {
  const { docs, pending } = buildDocs(`${HEADER}\npassport,護照/證件,,documents,,,,,\n`);
  assert.equal(docs.size, 0);
  assert.deepEqual(pending, ['passport']);
});

test('驗證錯誤:key 格式、重複、範圍不合法', () => {
  const { errors } = buildDocs(
    [
      HEADER,
      'Bad Key,名稱,,,100,,,,',
      'cup,杯子,,,100,,,,',
      'cup,杯子,,,100,,,,',
      'stove,爐頭,,,500,100,200,,',
      'pad,睡墊,,,,300,,,',
    ].join('\n'),
  );
  assert.equal(errors.length, 4);
});

test('diffDocs 只回傳有變動的列,並下架 CSV 移除的 key', () => {
  const base = {
    nameZh: '杯子',
    aliases: [],
    categoryId: null,
    weightGram: 100,
    weightMin: null,
    weightMax: null,
    note: null,
    isActive: true,
  };
  const existing = new Map([
    ['cup', { ...base, updatedAt: 'ts' }],
    ['old', { ...base, nameZh: '舊' }],
    ['gone', { ...base, isActive: false }],
  ]);
  const next = new Map([
    ['cup', base],
    ['new', { ...base, nameZh: '新' }],
  ]);
  const { upserts, deactivations } = diffDocs(existing, next);
  assert.deepEqual(
    upserts.map(([k]) => k),
    ['new'],
  );
  assert.deepEqual(deactivations, ['old']);
});
