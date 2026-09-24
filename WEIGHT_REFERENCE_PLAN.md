# PackPlan 參考重量 — 開發計劃

> 更新日期:2026-09-24 · 分支 `claude/weight-value-supabase-plan-1a960f`

## 1. 目標

清單中有顯示重量的地方,提供按鈕把「尚未填重量」的項目,用**線上參考重量庫**的值補上,並清楚標示哪些重量是線上資料。

- 從範本建立的項目一律是 `0 g`(`seed_data.dart` 的 `_buildFromGroups`),這些就是「缺重量」的項目。
- 每個範本項目都有穩定 key(如 `sleeping-bag`、`passport`),共 110 個,用來對應線上資料。

## 2. 已定案決策

| # | 題目 | 決定 |
|---|---|---|
| 1 | 線上資料誰維護 | 只由本人維護(xlsx → CSV → 匯入),v1 不開放使用者貢獻 |
| 2 | 單項補 | v1 就做(編輯對話框「帶入參考值」) |
| 3 | 自訂項目 | 用名稱比對(正規化後精確比對名稱/別名,不做模糊比對) |
| 4 | 重量範圍 | 顯示範圍;帶入「典型值」,只填範圍時取中間值 |
| 5 | 品牌型號 | 支援,掛在通用項目下(一層);**選型號時項目名稱改成型號名** |
| 6 | 後端 | **Firebase Firestore**(專案 `packplan-86e9d`),不用 Supabase |

**為何改用 Firebase**:Supabase 免費方案一個帳號最多 2 個 active 專案(已用滿),且 7 天閒置會自動暫停;Firestore 免費額度(每天 5 萬次讀取、1 GB)足夠,也不會暫停。

## 3. 後端架構(Firestore)

### 資料結構

- **`gear_weights/{item_key}`** — 每個項目或型號一份文件

  | 欄位 | 型別 | 說明 |
  |---|---|---|
  | nameZh | string | 顯示名稱;型號列為完整型號名 |
  | parentKey | string? | 型號列所屬的通用項目 key |
  | brand | string? | 品牌 |
  | aliases | string[] | 別名,供名稱比對 |
  | categoryId | string? | 分類參考 |
  | weightGram | int | 帶入值(典型值) |
  | weightMin / weightMax | int? | 參考範圍 |
  | note | string? | 備註 |
  | isActive | bool | false = 下架(不刪文件) |
  | updatedAt | timestamp | 增量同步用 |

- **`meta/gear_weights`** — `{ version, activeCount }`,App 先讀這 1 筆判斷要不要同步。

### 權限規則(已上線並驗證)

- `gear_weights`、`meta`:任何人可讀,不可寫
- 其他路徑:全部拒絕
- 寫入只透過匯入腳本(Admin SDK,不受規則限制)
- 驗證指令:`npm run check:rules`(4 項全 ✓)

### 同步策略

1. App 讀 `meta/gear_weights`(1 次讀取)
2. `version` 比本機新 → 只抓 `updatedAt > 上次同步時間` 的文件
3. 全部快取在手機,比對在本機做 → **離線也能補重量**

## 4. CSV 格式(`firebase/gear_weights.csv`)

欄位順序:`item_key, name_zh, parent_key, brand, aliases, category_id, weight_gram, weight_min, weight_max, note, is_active`

| 欄位 | 必填? | 規則 |
|---|---|---|
| item_key | **必填** | 小寫英數與 `-`,不可重複 |
| name_zh | **必填** | 型號列填完整型號名 |
| weight_gram 或 weight_min+max | 要上傳才填 | 三者皆空 → 待填、略過(不算錯) |
| parent_key | 型號列必填 | 通用項目留空;必須是 CSV 內已有的通用 key |
| brand | 選填 | |
| aliases | 選填 | 以 `\|` 分隔 |
| category_id | 選填 | |
| weight_min / weight_max | 選填 | 要嘛都填、要嘛都空 |
| note | 選填 | |
| is_active | 選填 | 空白 = 上架;`false` = 下架 |

注意:

- 標題列 11 個欄位都要在(順序可調)
- 重量只能是**正整數(公克)**,不能寫 `1.2kg`、`1,200`、`0`
- 任一列錯誤 → **整份不寫入**
- Excel 存檔選「CSV UTF-8」

品牌型號範例:

| item_key | name_zh | parent_key | brand | aliases | weight_gram |
|---|---|---|---|---|---|
| large-backpack | 大背包 | | | | 1500 |
| osprey-exos-58 | Osprey Exos 58 | large-backpack | Osprey | Exos 58 | 1200 |

## 5. 資料維護流程

```bash
cd firebase
export GOOGLE_APPLICATION_CREDENTIALS=~/dev_data/PackPlan/<金鑰檔>.json
npm run import:dry     # 預覽:列出新增/更新/下架
npm run import:apply   # 實際寫入
```

- 只寫入有變動的列;CSV 刪掉的 key 自動標為下架
- 服務帳戶金鑰:Console → 專案設定 → 服務帳戶 → 產生新的私密金鑰(存在 repo 外)

## 6. App 端設計

### 資料模型(已完成)

`PackItem` 新增:

- `weightSource`:`unset`(尚未填)/ `manual`(自填)/ `online`(線上)
- `catalogKey`:範本 key,自訂項目為 null
- 規則:範本項目建立時 `unset`;編輯時改了重量 → `manual`;批次/單項帶入 → `online`
- 舊資料相容:0 g → `unset`,其餘 → `manual`

### 參考重量服務(待做)

- `WeightReferenceService` 介面 + Firestore 實作 + 測試用 fake(比照 `CloudBackupScope` 注入)
- 本機快取 + 增量同步
- 比對:`catalogKey` 精確 → 名稱/別名正規化(去空白、轉小寫)精確比對

### UI 位置

| 位置 | 內容 |
|---|---|
| ① 清單詳情 `_WeightHeader` 下方 | 有缺重量時顯示「N 項尚未填重量 · 帶入參考重量」 |
| ② 批次補 bottom sheet | 預覽勾選清單(預設全選)、顯示範圍、查無資料另列、資料來源與更新日;套用後 SnackBar 可復原。**只帶通用值** |
| ③ `ChecklistTile` 重量文字 | 線上值顯示「1200 g ☁」(點 ☁ 看範圍);未填顯示淡色「— g」 |
| ④ 單項編輯對話框 | 重量欄旁「☁ 帶入參考值」;可選通用值或品牌型號,選型號時**名稱改為型號名** |
| ⑤ 總重附註 | 「含 N 項線上參考重量」 |

## 7. 進度

| 項目 | 狀態 | Commit |
|---|---|---|
| Firestore 資料庫建立(Standard,asia-east1) | ✅ 完成 | — |
| 權限規則上線 + 驗證腳本 | ✅ 完成 | `5ca092f` `fafd02f` |
| CSV 範本 + 匯入工具 + 測試 | ✅ 完成 | `5ca092f` |
| CSV 支援品牌型號 | ✅ 完成 | `8dee016` |
| App 第 1 步:資料模型 | ✅ 完成(76 測試綠) | `bc60036` |
| 填寫 CSV 重量 + 首次匯入 | ⏳ 需本人操作 | |
| App 第 2 步:串接 Firebase、快取、比對 | ⏳ 待做(需先 Firebase 登入) | |
| App 第 3 步:UI ①〜⑤ | ⏳ 待做 | |
| 真機測試(iOS / Android) | ⏳ 待做 | |

## 8. 需本人操作

### 在終端機登入 Firebase(一次)

App 端第 2 步的 `flutterfire configure` 需要全域的 `firebase` 指令,所以用全域安裝:

```bash
npm install -g firebase-tools
firebase login
```

1. 問是否允許收集使用資料 → 輸入 `n` 按 Enter
2. 自動開瀏覽器 → 選擁有 packplan 專案的 Google 帳號 → 允許
3. 終端機出現 `Success! Logged in as ...` 即完成

確認:

```bash
firebase projects:list
```

列表中看得到 `packplan-86e9d` 就代表登入成功。

### 其他

- 填 CSV 重量(可分批,沒填的會略過)
- 下載服務帳戶金鑰(匯入用)

## 9. 注意事項

- 免費額度:每讀一份文件算 1 次;以 500 筆計,每天約可支撐 100 位新使用者首次下載。量大時可改成「整份資料放 1 份文件」(1 次讀取)
- 型號只支援一層(型號不能再掛型號)
- 批次補不會自動選型號,避免帶錯
