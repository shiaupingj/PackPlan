# 打包工具 App — 商業版 Wireframe（低保真設計稿）

> 目標：提供可直接交付設計 / 工程的畫面結構與互動邏輯（iOS / Android 共用）

---

## 一、整體架構（App Sitemap）

```
首頁（清單列表）
 ├── 建立新清單
 │    ├── 選擇範本
 │    ├── 設定天數 + 天氣
 │    └── 生成清單
 │
 ├── 清單詳情頁
 │    ├── 分類（兩層）
 │    ├── 重量統計
 │    ├── UL模式
 │    ├── 超重提醒
 │    └── 分享
 │
 ├── 範本中心（付費）
 │
 └── 我的（帳號/設定）
```

---

## 二、首頁（清單列表）

```
[Header]
  打包清單

[+ 建立新清單]

------------------------
| 🏔 登山｜3天2夜       |
| 重量：8.2 kg         |
| 進度：65%            |
------------------------

------------------------
| ✈️ 城市旅遊｜5天      |
| 重量：12 kg          |
| 進度：20%            |
------------------------
```

👉 互動
- 點擊卡片 → 進入清單詳情
- 長按 → 刪除 / 複製

---

## 三、建立清單流程

### Step 1：選擇範本

```
選擇類型

[城市旅遊]  [登山]  [露營]

（可滑動）
[🔥熱門範本]
- 新手登山包
- 輕量露營包（Pro）🔒
```

👉 Pro範本需付費解鎖

---

### Step 2：設定條件

```
天數
[-] 3 天 [+]

天氣
( ) 晴天
( ) 雨天
( ) 寒冷

[建立清單]
```

👉 邏輯
- 衣物數量 = 天數 × 基礎值
- 天氣影響裝備（如雨衣）

---

## 四、清單詳情頁（核心畫面）

```
[Header]
登山｜3天2夜

重量：8.2 kg  ⚠️（超重）
[UL模式] [分享]

------------------------
▾ 背包（3.2 kg）
  ☐ 水壺（500g）
  ☐ 頭燈（100g）
  ☐ 行動電源（300g）

▾ 衣物（2.5 kg）
  ☐ 上衣 x3
  ☐ 褲子 x2

▾ 食物（2.5 kg）
  ☐ 能量棒

[+ 新增項目]
```

---

## 五、關鍵功能設計

### 5.1 重量系統（可視化）

```
重量條（Progress Bar）

[████████░░] 8.2 / 7 kg
⚠️ 已超重 1.2kg
```

---

### 5.2 超重提醒（智慧建議）

```
⚠️ 建議優化：
- 移除「備用鞋」（800g）
- 減少衣物 1 件
- 使用輕量鍋具（Pro建議）
```

👉 邏輯
- 找出最重項目
- 推薦替代方案（未來可接商業）

---

### 5.3 UL 模式（輕量化）

```
開啟 UL 模式

✔ 隱藏非必要物品
✔ 標記「可刪減」項目
✔ 顯示最低可行重量

→ 最低重量：5.6 kg
```

---

### 5.4 兩層結構互動

👉 分類（可收合）
👉 Item 支援：
- 勾選
- 編輯重量
- 拖曳排序

---

### 5.5 分享功能

```
分享清單

[產生連結]
[分享給朋友]

或

轉成圖片（IG/LINE）
```

---

## 六、範本中心（商業核心）

```
範本商店

免費
- 基礎登山

付費（$30~$150）
🔒 高山縱走專業包
🔒 極簡露營（UL）
🔒 攝影旅遊包

[購買 / 解鎖]
```

👉 成長關鍵：
- KOL 範本
- 專業裝備清單

---

## 七、我的（帳號）

```
我的

- 我的範本
- 已購買項目
- 單位設定（kg / g）
- 雲端同步
```

---

## 八、關鍵 UX 原則

1. 「一眼看到重量」優先
2. 4 步內完成清單建立（範本、旅程設定、項目選擇、確認）
3. 編輯動作 ≤ 1 秒完成
4. 所有計算即時回饋

---

## 九、差異化亮點（商業版）

✔ 天氣 + 天數自動生成
✔ UL 輕量化模式（核心賣點）
✔ 智慧減重建議（未來可接電商）
✔ 範本商店（營收來源）
✔ 分享機制（成長來源）

---

## 十、下一步（建議）

如果要真正進入開發，下一步應該做：

1. 高保真 UI（Figma）
2. Design System（元件）
3. 工程 API / 資料結構細化

---

（Wireframe 結束）

---

# 十一、高保真 UI 設計方向（Visual Design）

## 設計風格定位：
👉 「戶外 × 極簡工具」混合風格

- 基調：乾淨 + 功能導向
- 輔助：戶外探險感（但不粗糙）

---

## 色彩系統

### 主色
- 深綠（Primary）：#1F3D2B（戶外 / 專業感）

### 輔助色
- 草綠：#4CAF50（成功 / 完成）
- 橘色：#FF8C42（提醒 / 超重）

### 中性色
- 背景：#F7F7F7
- 卡片：#FFFFFF
- 文字：#222222

---

## 字體建議

- iOS：SF Pro
- Android：Roboto

👉 字重使用：
- 標題：Semibold
- 內容：Regular

---

## 元件設計（Design System）

### 卡片（清單）
- 圓角：16px
- 陰影：輕微（浮起感）
- 內容：
  - 標題
  - 重量
  - 進度條

---

### 按鈕

Primary：
- 背景：深綠
- 文字：白

Secondary：
- 邊框：灰
- 背景：透明

---

### 勾選項目（Checklist）

- 未完成：空心圓
- 完成：✔ + 淡化文字

---

### 重量條（關鍵元件）

- 正常：綠色
- 接近上限：橘色
- 超重：紅色 + 動畫提示

---

# 十二、品牌風格（Branding）

## 品牌核心

👉 「聰明打包，而不是多帶」

不是 checklist 工具，而是：
👉 行動決策工具

---

## 品牌關鍵字

- 輕量（Lightweight）
- 精準（Smart）
- 掌控（Control）
- 戶外（Adventure）

---

## 品牌語氣（Tone of Voice）

- 簡短
- 有判斷（不像工具，更像教練）

### 範例

❌ 不好：
「你目前重量過高」

✅ 建議：
「你背太多了。」

---

## App 命名建議（可選）

- PackLite
- TrailPack
- PackSmart
- UL Bag

---

## 空狀態設計（很重要）

### 無清單

「還沒準備？我們幫你開始。」
[建立第一個清單]

---

### 無項目

「這個包太空了，該放點東西。」

---

## 分享視覺（成長關鍵）

分享卡片設計：

```
🏔 登山 3天2夜

總重量：5.6kg

✔ UL玩家
✔ 已優化裝備

（清單摘要）
```

👉 可直接發 IG / LINE

---

## 動效建議（提升質感）

- 勾選 → 淡出 + 滑動
- 超重 → 輕微震動 + 顏色變化
- UL 模式 → 整體變簡潔（動畫切換）

---

# 十三、結論（產品定位完成）

這個產品不再只是：
❌ 打包清單 App

而是：
✅ 「戶外打包決策工具 + 輕量化教練」


（商業版設計稿完成）

---

# 十四、UL 玩家等級系統 UI（高保真畫面規格）

## 1️⃣ 等級總覽卡（首頁 / 清單頁頂部）

```
┌────────────────────────┐
│ 🪶 UL 等級             │
│                        │
│ UL 玩家                │
│ 1.8 kg / 天            │
│                        │
│ [████████░░]           │
│ 距離下一級還差 0.6kg   │
└────────────────────────┘
```

設計重點：
- 大字顯示「身份」（不是數字）
- 次要資訊才是 kg/day
- 進度條要有「逼近感」

---

## 2️⃣ 升級彈窗（核心體驗）

```
（全螢幕半透明背景 + 中央卡片）

🎉 升級成功！

你現在是

【 UL 玩家 】

比 78% 的人更輕

[分享我的成就]
[繼續優化]
```

動效：
- 卡片 scale in（放大）
- 背景淡入
- 等級文字閃動

---

## 3️⃣ UL 模式畫面（開啟狀態）

```
[UL 模式 ON]

⚠️ 建議減重

- 備用鞋（800g） → 建議移除
- 外套（600g） → 可替代

------------------

▾ 背包
  ⚠️ 水壺（500g）
  ⚠️ 行動電源（300g）

（灰化非必要項目）
```

設計重點：
- 高亮「可以刪」的東西
- 非必要項目降低視覺權重

---

## 4️⃣ 等級進度頁（點擊等級卡進入）

```
你的 UL 等級

目前：UL 玩家

------------------

📊 分析

平均：1.8 kg / 天
最佳：1.5 kg / 天

------------------

下一級：極簡大師
條件：< 1.2 kg / 天

還差：0.6 kg

[查看優化建議]
```

---

## 5️⃣ 分享卡 UI（成長核心）

```
┌────────────────────┐
│ 🏔 3天2夜登山       │
│                    │
│ 總重量：5.6kg       │
│                    │
│ 🪶 UL 玩家         │
│ 比 82% 的人更輕     │
│                    │
│ #PackLite          │
└────────────────────┘
```

設計重點：
- 乾淨（像海報）
- 可直接社群分享
- 有品牌露出（但不突兀）

---

## 6️⃣ 等級標籤（小元件）

用於各處顯示（清單卡 / 分享）

```
[🪶 UL 玩家]
```

樣式：
- 膠囊形（rounded）
- 淺背景 + 深字

---

## 7️⃣ 顏色對應等級

- Beginner：灰
- Light Pack：綠
- Smart：深綠
- UL：藍綠（品牌色延伸）
- Minimalist：金色（稀有）

👉 用顏色建立「等級感」

---

## 8️⃣ 微互動（關鍵細節）

- 勾選物品 → 重量即時下降（數字動畫）
- 超重 → header 震動 + 變橘
- 接近升級 → 進度條發光

---

## 9️⃣ UX 節奏（很重要）

1. 建立清單 → 立即看到重量
2. 開 UL → 發現可以刪的東西
3. 減重 → 接近升級
4. 升級 → 分享

👉 這是一個「循環」

---

# 十五、結論（UI 完成）

這套 UI 的目的不是美觀，而是：

✅ 讓使用者一直優化重量
✅ 讓使用者產生成就感
✅ 讓使用者願意分享


（UL 等級 UI 設計完成）

---

# 進階功能規格（Future Versions / Advanced Specs）

> 本區為 v2 之後規劃。每個功能包含三層：**功能邏輯**、**畫面設計**、**技術規格（資料結構 / API / 計算）**。
> 共用前置定義見「附錄：共用資料模型」。

---

# 十六、裝備庫 Gear Locker（v2 核心基礎）

## 16.1 功能定位

> 一句話：使用者的「裝備資產資料庫」，清單從庫裡「拉」物品，而不是每次重打。

痛點：使用者重複使用同一批裝備，每次建立清單都要重新輸入名稱與重量。
價值：一次建檔、永久複用，並成為「重量分佈」「UL 等級」「智慧減重」的資料來源。

定位：**免費功能**（基礎留存與資料累積），但庫容量上限可作為 Pro 升級點（見 16.6）。

---

## 16.2 功能邏輯

1. **建檔**：使用者新增一件裝備（名稱、重量、分類、標籤、是否消耗品）。
2. **複用**：建立 / 編輯清單時，從裝備庫挑選 → 自動帶入重量與分類。
3. **單一真實來源（SSOT）**：清單中的項目「引用」裝備庫，修改裝備庫重量時，**新加入**的清單套用新值；既有清單採快照（snapshot）不被回溯修改（避免歷史清單被竄改）。
4. **使用統計**：記錄每件裝備被加入幾個清單、最後使用時間 → 排序「最常用 / 最近用」。
5. **匯入**：可從既有清單「收藏」項目回裝備庫（反向建檔）。

---

## 16.3 畫面設計

### 裝備庫主頁

```
[Header]
我的裝備庫            [+ 新增裝備]

[🔍 搜尋]   [分類 ▾]  [排序：最常用 ▾]

------------------------
背包系統
  🎒 主背包 60L        1,250 g   ·用過 8 次
  🛏 睡袋               780 g    ·用過 5 次
------------------------
炊事
  🔥 鈦鍋               145 g    ·用過 3 次
  ⛽ 瓦斯爐             88 g     ·消耗品
------------------------
```

👉 互動
- 點品項 → 編輯（名稱 / 重量 / 分類 / 消耗品 / 標籤）
- 長按 → 刪除 / 複製 / 「加入目前清單」
- 右上排序：最常用 / 最近用 / 重量高→低 / A→Z

### 從裝備庫加入清單（清單詳情頁的「+ 新增項目」改版）

```
新增項目                     [手動輸入]

[🔍 從裝備庫搜尋]

✓ 主背包 60L     1,250 g
☐ 睡袋           780 g
☐ 鈦鍋           145 g

[加入所選 (1)]
```

👉 多選一次加入；已在清單中的項目顯示「已加入」灰態。

---

## 16.4 技術規格

### 資料結構

```ts
// 裝備庫單品（使用者層級，跨清單共用）
interface GearItem {
  id: string;              // uuid
  ownerId: string;
  name: string;
  weightGram: number;      // 一律以公克儲存，顯示層再轉換
  categoryId: string;      // 對應分類（兩層結構之子類）
  isConsumable: boolean;   // 影響 base weight 計算（見十七章）
  isWorn: boolean;         // 穿戴裝備，預設 false
  tags: string[];          // 自由標籤，如 "三季", "雪地"
  note?: string;
  usageCount: number;      // 被加入清單次數
  lastUsedAt?: string;     // ISO 8601
  createdAt: string;
  updatedAt: string;
}

// 清單中的項目（引用裝備庫 + 快照）
interface ListItem {
  id: string;
  listId: string;
  gearItemId?: string;     // 來源裝備庫 id；手動輸入則為 null
  nameSnapshot: string;    // 加入當下的快照（避免回溯竄改）
  weightGramSnapshot: number;
  quantity: number;        // 數量，如「上衣 x3」
  categoryId: string;
  isConsumable: boolean;
  isWorn: boolean;
  checked: boolean;
  sortOrder: number;
}
```

### API

| Method | Endpoint | 說明 |
|---|---|---|
| GET | `/gear` | 取得裝備庫（支援 `?sort=usage&category=&q=`） |
| POST | `/gear` | 新增裝備 |
| PATCH | `/gear/:id` | 編輯（不回溯既有清單） |
| DELETE | `/gear/:id` | 刪除（既有清單因有快照不受影響） |
| POST | `/lists/:id/items/from-gear` | body: `{ gearItemIds: string[] }` 批次加入並寫快照、`usageCount++` |
| POST | `/gear/from-list-item` | 將清單項目收藏回裝備庫 |

### 關鍵規則
- 重量一律存 `gram`，顯示依使用者單位設定（kg/g）換算。
- 加入清單時複製 `nameSnapshot` / `weightGramSnapshot`，建立後即與裝備庫脫鉤。
- `usageCount` 與 `lastUsedAt` 在批次加入時更新。

---

## 16.5 邊界與空狀態
- 空庫：「裝備庫是空的。從清單收藏，或手動新增第一件裝備。」
- 刪除被引用的裝備：允許，提示「既有清單不受影響」。

## 16.6 商業掛勾（可選）
- 免費上限 50 件；Pro 無限。
- 與十八章「重量分佈」、十七章「base weight」共用此資料層。

---

# 十七、Base Weight 與消耗品分離（UL 專業度核心）

## 17.1 功能定位

> 一句話：把背包重量拆成「基重 / 消耗品 / 穿戴」，讓 UL 等級真正專業。

UL 圈的核心觀念：
- **Base Weight（基重）**：扣掉食物、水、燃料等會用完的東西後的「背負重量」。這是 UL 玩家真正比較的數字。
- **Consumables（消耗品）**：食物、水、瓦斯、行動電源耗電 → 行程中會減少。
- **Worn Weight（穿戴重量）**：出發時穿在身上的衣物鞋子，不計入背包重量。

沒有這個分離，現有的「UL 等級（kg/day）」判定不夠專業，會被進階使用者質疑。

---

## 17.2 功能邏輯

每個項目有三種重量歸類（互斥）：
1. `packed`（預設）→ 計入 base weight
2. `consumable` → 計入 total，不計入 base weight
3. `worn` → 不計入 total pack weight（但仍顯示供參考）

重量定義：

```
Total Pack Weight = Σ(packed) + Σ(consumable)        // 背在身上的全部
Base Weight       = Σ(packed)                          // UL 比較基準
Worn Weight       = Σ(worn)                            // 參考，不計入背包
Skin-out Weight   = Total Pack Weight + Worn Weight    // 全身總重（進階指標）
```

UL 等級判定改為以 **Base Weight** 為主（取代原本籠統的 kg/day）。

---

## 17.3 畫面設計

### 清單頂部重量摘要（取代原單一重量條）

```
[Header] 登山｜3天2夜

總背重 8.2 kg
├ 基重     5.6 kg   🪶
└ 消耗品   2.6 kg   (食物/水/燃料)
穿戴 1.4 kg（不計背重）

[████████░░] 基重 5.6 / 6.0 kg ✔
```

👉 點「基重 / 消耗品」可展開只看該類項目。

### 項目重量類型切換（編輯項目時）

```
能量棒
重量 [  120 ] g    數量 [ 6 ]

類型：
( ) 一般裝備（計入基重）
(•) 消耗品（食物/水/燃料）
( ) 穿戴（不計背重）
```

### UL 等級頁更新（呼應第十四章）

```
你的 UL 等級
依「基重」評定

目前基重：5.6 kg → 🪶 UL 玩家
下一級：極簡大師  基重 < 4.5 kg
還差：1.1 kg
```

---

## 17.4 技術規格

### 資料結構（擴充 ListItem）

```ts
type WeightClass = 'packed' | 'consumable' | 'worn';

interface ListItem {
  // ...既有欄位
  weightClass: WeightClass;   // 取代原 isConsumable/isWorn 兩個 bool
}
```

> 遷移：`isConsumable=true → consumable`；`isWorn=true → worn`；其餘 `packed`。

### 計算（純函式，client 端即時運算）

```ts
function summarizeWeights(items: ListItem[]) {
  const sum = (f: (i: ListItem) => boolean) =>
    items
      .filter(f)
      .reduce((g, i) => g + i.weightGramSnapshot * i.quantity, 0);

  const packed = sum(i => i.weightClass === 'packed');
  const consumable = sum(i => i.weightClass === 'consumable');
  const worn = sum(i => i.weightClass === 'worn');

  return {
    baseWeight: packed,
    totalPackWeight: packed + consumable,
    wornWeight: worn,
    skinOutWeight: packed + consumable + worn,
  };
}
```

### UL 等級門檻（以 base weight，公克）

| 等級 | 顏色 | Base Weight 門檻 |
|---|---|---|
| Beginner | 灰 | ≥ 9000 g |
| Light Pack | 綠 | < 9000 g |
| Smart | 深綠 | < 7000 g |
| UL 玩家 | 藍綠 | < 5500 g |
| 極簡大師 | 金 | < 4500 g |

> 門檻可由後端 config 下發，方便日後調整與分客群（如「三天行程」用不同門檻）。

---

## 17.5 與其他功能的關係
- 「智慧減重建議（5.2）」改為優先針對 `packed` 高重量項目（消耗品不建議刪）。
- 「重量分佈（十八章）」可切換「總重 / 僅基重」視角。

---

# 十八、重量分佈視覺化（Weight Breakdown）

## 18.1 功能定位

> 一句話：不只看「總重多少」，更要一眼看出「重量花在哪」。

延伸 UX 原則「一眼看到重量」：把分類重量做成可視化，讓使用者知道下手減重該砍哪一類。

---

## 18.2 功能邏輯

1. 依分類彙總重量與佔比 → 環圈圖（donut）或橫條佔比圖。
2. 視角切換：**總背重 / 僅基重**（呼應十七章）。
3. 互動：點某分類 → 跳轉清單該分類並展開。
4. 與 UL 模式聯動：開 UL 時，圖上標出「可刪減」貢獻的重量（虛線區塊）。
5. 顯示「最重前三項」快捷減重入口。

---

## 18.3 畫面設計

```
重量分佈                 視角：[總背重 ▾]

        ╭───────╮
       ╱  炊事   ╲       背包系統 38%  ███████ 3.1kg
      │   18%     │      衣物     25%  █████   2.1kg
      │  ╭─────╮  │      炊事     18%  ████    1.5kg
       ╲ │5.6kg│ ╱       食物     12%  ██      1.0kg
        ╲╰─────╯╱        其他      7%  █       0.5kg
         ╰─────╯

最重前三項
1. 主背包 60L      1,250 g   [優化]
2. 帳篷            1,100 g   [優化]
3. 睡袋             780 g    [優化]
```

👉 點環圈某段或右側橫條 → 跳到清單該分類。
👉 「優化」按鈕 → 進入 5.2 智慧減重建議。

---

## 18.4 技術規格

### 計算（純函式）

```ts
interface CategoryBreakdown {
  categoryId: string;
  categoryName: string;
  totalGram: number;
  percent: number;        // 0–100，四捨五入
  color: string;
}

function breakdownByCategory(
  items: ListItem[],
  view: 'total' | 'base',
): CategoryBreakdown[] {
  const pool = view === 'base'
    ? items.filter(i => i.weightClass === 'packed')
    : items.filter(i => i.weightClass !== 'worn');

  const grand = pool.reduce((g, i) => g + i.weightGramSnapshot * i.quantity, 0);
  const byCat = groupBy(pool, i => i.categoryId);

  return Object.entries(byCat)
    .map(([categoryId, list]) => {
      const totalGram = list.reduce(
        (g, i) => g + i.weightGramSnapshot * i.quantity, 0);
      return {
        categoryId,
        categoryName: nameOf(categoryId),
        totalGram,
        percent: grand ? Math.round((totalGram / grand) * 100) : 0,
        color: colorOf(categoryId),
      };
    })
    .sort((a, b) => b.totalGram - a.totalGram);
}
```

- 純前端計算，無需新增 API；資料來自既有清單。
- 圖表建議用輕量 SVG 自繪（避免引入重型 chart 套件，符合 app 體積考量）。
- 顏色沿用第十一章色彩系統，分類超過 6 類時其餘併為「其他」。

---

# 十九、協作清單 Collaborative List（Pro 付費功能）

## 19.1 功能定位

> 一句話：把「分享唯讀連結」升級成「多人共編 + 分配誰帶什麼」。

定位：**Pro 付費功能**。免費版維持唯讀分享（第 5.5 節）；協作共編為 Pro 專屬。

典型情境：家庭旅遊、團隊登山、社團出隊 —— 需要分配「誰帶帳篷、誰帶炊具」，並避免重複帶。

---

## 19.2 功能邏輯

1. **邀請成員**：清單擁有者（Pro）以連結 / QR 邀請。被邀請者**免 Pro 也能參與共編**（付費門檻在「建立協作」的擁有者）。
2. **角色權限**：
   - `owner`：全部權限（含刪清單、移除成員、轉移擁有權）
   - `editor`：增刪改項目、認領
   - `viewer`：唯讀
3. **認領（Claim）**：每個項目可被某成員「認領」→ 顯示頭像，代表由他攜帶。
4. **避免重複**：同一品項被多人勾選時提示「已有人認領」。
5. **個人視角**：成員可篩「只看我要帶的」→ 產生個人打包子清單與個人重量。
6. **即時同步**：多人同時編輯需即時更新與衝突處理。

---

## 19.3 畫面設計

### 協作清單詳情（成員視角）

```
[Header] 🏔 谷關團隊登山        [👥 4]

總重 24.6 kg（團隊）
我的負重 6.2 kg

篩選：[全部] [只看我要帶的]

▾ 炊事（4.5 kg）
  ✓ 鈦鍋 145g          👤 小明
  ☐ 瓦斯爐 88g         👤 你   [取消認領]
  ☐ 餐具組 200g        [認領]

▾ 帳篷（3.0 kg）
  ☐ 雙人帳 1,800g      👤 阿華
```

### 成員管理（owner）

```
協作成員                 [+ 邀請]

👤 你（擁有者）
👤 小明   editor   [▾]
👤 阿華   editor   [▾]
👤 小美   viewer   [▾]

[產生邀請連結]  [QR Code]
```

### 邀請落地頁

```
小明 邀請你協作

🏔 谷關團隊登山
4 位成員 · 38 個項目

[加入協作]
（需登入）
```

---

## 19.4 技術規格

### 資料結構

```ts
interface ListMember {
  listId: string;
  userId: string;
  role: 'owner' | 'editor' | 'viewer';
  displayName: string;
  avatarUrl?: string;
  joinedAt: string;
}

// 擴充 ListItem
interface ListItem {
  // ...既有欄位
  claimedBy?: string;      // userId，未認領為 null
  updatedBy: string;       // 最後修改者（衝突顯示用）
  version: number;         // 樂觀鎖版本號
}

interface ListInvite {
  token: string;           // 隨機不可猜
  listId: string;
  role: 'editor' | 'viewer';
  expiresAt: string;
  maxUses?: number;
  usedCount: number;
}
```

### API

| Method | Endpoint | 權限 | 說明 |
|---|---|---|---|
| POST | `/lists/:id/invites` | owner | 產生邀請（回 token / 連結 / QR） |
| POST | `/invites/:token/accept` | 登入者 | 加入為成員 |
| GET | `/lists/:id/members` | member | 成員列表 |
| PATCH | `/lists/:id/members/:uid` | owner | 改角色 / 移除 |
| POST | `/lists/:id/items/:itemId/claim` | editor | 認領（body 空，認領為自己） |
| DELETE | `/lists/:id/items/:itemId/claim` | editor | 取消認領 |
| PATCH | `/lists/:id/items/:itemId` | editor | 編輯（帶 `version` 做樂觀鎖） |

### 即時同步
- 傳輸：WebSocket（或 Firebase Realtime / Supabase Realtime，視後端選型）。
- 事件：`item.updated` / `item.claimed` / `member.joined` / `member.role_changed`。
- **衝突處理**：樂觀鎖，PATCH 帶 `version`；版本不符回 `409`，client 拉最新並提示「阿華剛改了這項」。
- 認領為冪等操作；競態時「先到先得」，後者收到 409 並顯示已認領者。

### 重量計算延伸

```ts
// 個人負重
function memberLoad(items: ListItem[], userId: string) {
  return items
    .filter(i => i.claimedBy === userId)
    .reduce((g, i) => g + i.weightGramSnapshot * i.quantity, 0);
}
// 團隊總重 = 全部項目（含未認領）
```

### 商業 / 權限規則
- **建立協作清單**需 owner 為 Pro；非 Pro 嘗試 → 導購升級頁。
- 被邀請的 editor/viewer **不需 Pro**（擴大病毒式成長，付費壓在發起人）。
- 免費版分享維持唯讀（5.5）；唯讀連結與協作邀請為兩條不同路徑。

---

# 附錄：共用資料模型與導入順序

## A. 重量單位
- 全系統內部一律以 `gram`（整數）儲存與計算，顯示層依使用者設定（kg / g）換算與四捨五入。

## B. 分類結構
- 沿用第四章「兩層分類」：`Category(parent) → SubCategory`。`categoryId` 指向子類。

## C. 建議導入順序（依相依關係）
1. **十六 裝備庫** —— 其他功能的資料來源，先做。
2. **十七 Base Weight 分離** —— 修正 UL 等級邏輯，影響面廣，緊接著做。
3. **十八 重量分佈** —— 純前端、相依前兩者的資料，快速見效。
4. **十九 協作清單（Pro）** —— 需後端即時同步與付費系統，最後做。

## D. 與現有章節的關係對照
| 新功能 | 影響 / 延伸的既有章節 |
|---|---|
| 裝備庫 | 4.「+ 新增項目」、7.「我的範本」 |
| Base Weight | 5.1 重量系統、5.2 減重建議、十四 UL 等級 |
| 重量分佈 | 5.1 重量系統、5.3 UL 模式 |
| 協作清單 | 5.5 分享、六 範本中心（付費）、七 雲端同步 |

（進階功能規格結束）
