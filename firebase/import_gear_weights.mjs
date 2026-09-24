// 把 gear_weights.csv 同步到 Firestore(packplan-86e9d)。
//
// 用法:
//   node import_gear_weights.mjs gear_weights.csv          # 預覽(不寫入)
//   node import_gear_weights.mjs gear_weights.csv --apply  # 實際寫入
//
// 認證:設定環境變數 GOOGLE_APPLICATION_CREDENTIALS 指向服務帳戶金鑰 JSON
// (Firebase Console → 專案設定 → 服務帳戶 → 產生新的私密金鑰)。金鑰請放在 repo 外。
//
// CSV 是唯一資料來源:只寫入有變動的列;CSV 裡刪掉的 key 會標成 isActive=false(不刪文件,
// App 增量同步才收得到下架)。有變動時更新 meta/gear_weights.version,App 以此判斷要不要同步。

import { readFileSync } from 'node:fs';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { buildDocs, diffDocs } from './gear_weights_csv.mjs';

const PROJECT_ID = 'packplan-86e9d';
const COLLECTION = 'gear_weights';
const META_DOC = 'meta/gear_weights';
const BATCH_LIMIT = 400;

const args = process.argv.slice(2);
const csvPath = args.find((a) => !a.startsWith('--'));
const apply = args.includes('--apply');

if (!csvPath) {
  console.error('用法:node import_gear_weights.mjs <csv> [--apply]');
  process.exit(1);
}

const { docs, pending, errors } = buildDocs(readFileSync(csvPath, 'utf8'));

if (errors.length > 0) {
  console.error(`CSV 有 ${errors.length} 個錯誤,未寫入任何資料:`);
  for (const e of errors) console.error(`  ✗ ${e}`);
  process.exit(1);
}

initializeApp({ credential: applicationDefault(), projectId: PROJECT_ID });
const db = getFirestore();

const snapshot = await db.collection(COLLECTION).get();
const existing = new Map(snapshot.docs.map((d) => [d.id, d.data()]));
const { upserts, deactivations } = diffDocs(existing, docs);

console.log(`CSV:${docs.size} 筆有重量,${pending.length} 筆待填(略過)`);
console.log(`Firestore 現有:${existing.size} 筆`);
console.log(`→ 新增/更新 ${upserts.length} 筆,下架 ${deactivations.length} 筆`);
for (const [key, doc] of upserts) {
  const range = doc.weightMin ? `(${doc.weightMin}–${doc.weightMax})` : '';
  console.log(`  ${existing.has(key) ? '~' : '+'} ${key} ${doc.nameZh} ${doc.weightGram}g${range}`);
}
for (const key of deactivations) console.log(`  - ${key}`);

if (upserts.length === 0 && deactivations.length === 0) {
  console.log('沒有變動。');
  process.exit(0);
}
if (!apply) {
  console.log('\n(預覽模式,加 --apply 才會寫入)');
  process.exit(0);
}

const ops = [
  ...upserts.map(([key, doc]) => (batch) =>
    batch.set(db.collection(COLLECTION).doc(key), {
      ...doc,
      updatedAt: FieldValue.serverTimestamp(),
    }),
  ),
  ...deactivations.map((key) => (batch) =>
    batch.update(db.collection(COLLECTION).doc(key), {
      isActive: false,
      updatedAt: FieldValue.serverTimestamp(),
    }),
  ),
];

for (let i = 0; i < ops.length; i += BATCH_LIMIT) {
  const batch = db.batch();
  ops.slice(i, i + BATCH_LIMIT).forEach((op) => op(batch));
  await batch.commit();
}

const activeCount = [...docs.values()].filter((d) => d.isActive).length;
await db.doc(META_DOC).set({
  version: FieldValue.serverTimestamp(),
  activeCount,
});

console.log(`\n✓ 已寫入 ${ops.length} 筆,線上有效資料 ${activeCount} 筆。`);
