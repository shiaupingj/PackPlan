# PackPlan 手機 App 開發計畫

> 依據：`PRD.md`
> 目標平台：iOS App Store、Android Google Play
> 技術基礎：Flutter 單一程式碼庫，雙平台發佈

## 1. 產品目標

PackPlan 不是一般 checklist app，而是「戶外打包決策工具 + 輕量化教練」。第一版應優先讓使用者快速建立清單、即時看到重量、理解是否超重，並透過超輕量化打包得到可行的減重建議。

核心成功標準：

- 4 步內完成第一份打包清單，並可在建立前選擇需要的項目。
- 清單詳情頁一眼看到總重、上限、進度與超重狀態。
- 所有重量計算在本機即時回饋，勾選、編輯、增刪項目後立即更新。
- iOS 與 Android 都能以相同功能上架，平台差異只保留在系統分享、權限、商店付費流程。

## 2. 目前專案狀態

截至 2026-07-01，Flutter 專案已有：

- iOS / Android 專案骨架與正式 app shell。
- `清單 / 範本 / 我的` 三分頁，以及四步建立清單流程。
- 清單新增、複製、刪除、項目編輯、分類收合與拖曳排序。
- 即時重量、超重、接近上限、最重項目與超輕量化建議。
- 每份清單可切換重量顯示，並可重新命名、拖曳排列分類。
- 項目可標記為一般裝備或身上穿戴；穿戴重量不計入背包總重。
- SQLite 本機持久化、版本化 JSON 匯出／匯入與資料驗證。
- 資料庫啟動失敗／損毀復原畫面，可重新嘗試或重建本機資料。
- iOS `UIActivityViewController` 與 Android `ACTION_SEND` 原生文字分享。
- repository、備份、持久化、重量計算、分享 channel 與主要 UI widget tests。

目前已進入 Phase 2 品質驗收；下一步是完成 iOS / Android 裝置實測、
上架素材、平台簽署與商店設定。

## 3. 發佈策略

### MVP 1.0：離線可用版本

目標：先做出可上架、可留存、可驗證核心價值的版本。

包含：

- 首頁清單列表。
- 建立清單流程：選範本、設定天數與天氣、生成清單。
- 清單詳情：兩層分類、勾選、重量統計、超重提醒。
- 超輕量化打包：標記可刪減項目、顯示最低可行重量。
- 本機儲存：清單、項目、範本、使用者設定。
- 系統分享：文字分享與圖片分享擇一先完成。

暫不包含：

- 帳號系統。
- 雲端同步。
- 付費範本商店。
- 多人協作。

### 1.1：商業化準備版本

目標：加入可付費解鎖的產品骨架，但避免一開始就被後端拖慢。

包含：

- 範本中心頁。
- 免費 / Pro 範本區分。
- 已購買項目頁。
- App Store / Google Play 內購串接。
- 上架所需的隱私政策、服務條款、商店素材。

### 2.0：進階 UL 與長期留存版本

目標：深化專業度與留存，讓使用者持續維護自己的裝備資料。

包含：

- 裝備庫 Gear Locker。
- Base Weight、消耗品、穿戴重量分離。
- 重量分佈視覺化。
- UL 等級頁與升級分享。

### 3.0：雲端與 Pro 協作版本

目標：做出明確付費價值與病毒式成長。

包含：

- 登入與雲端同步。
- 唯讀分享連結。
- Pro 協作清單。
- 成員角色、認領項目、個人負重。
- 即時同步與衝突處理。

## 4. 開發階段

### Phase 0：產品與工程基礎整理，約 1 週

產出：

- 將 `DesignSystemGallery` 改為正式 app shell。
- 決定狀態管理方案，例如 Riverpod 或 Bloc。
- 決定本機資料庫方案，例如 Drift、Isar 或 Hive。
- 建立核心 domain model。
- 建立 app navigation 架構。
- 下方導覽列採用 `清單 / 範本 / 我的` 三分頁，先完成可切換版本再進入 Phase 1。
- 補齊基礎測試結構。

建議資料模型：

- `PackList`：清單主檔，含類型、天數、天氣、重量上限、建立時間。
- `PackCategory`：兩層分類。
- `PackItem`：項目，含名稱、重量、數量、勾選、必要性、排序。
- `Template`：範本，含免費 / Pro 標記。
- `UserSettings`：單位、重量上限預設值、通知與偏好。

完成條件：

- App 啟動後進入正式首頁，不再是 design system preview。
- 底部導覽列可在 `清單`、`範本`、`我的` 三個主要入口間切換。
- Domain model 與 sample data 可跑通。
- Widget test 覆蓋首頁初始渲染與底部導覽切換。
- iOS simulator 與 Android emulator 都能正常啟動。

### Phase 1：MVP 核心流程，約 3 至 4 週

#### 1. 首頁清單列表

功能：

- 顯示所有清單卡片。
- 顯示類型、天數、目前重量、完成進度。
- 點擊卡片進入詳情。
- 長按支援複製、刪除。
- 空狀態顯示「還沒準備？我們幫你開始。」

驗收：

- 沒有清單時可引導建立第一份清單。
- 清單新增、刪除、複製後列表立即更新。

#### 2. 建立清單流程

功能：

- Step 1：選擇類型與範本。
- Step 2：設定天數、天氣，以及是否加入身上穿戴。
- Step 3：依分類多選要加入的項目。
- Step 4：確認並生成清單，進入詳情。
- 天數影響衣物數量。
- 天氣影響雨具、保暖、防曬等項目。

驗收：

- 使用者可在 4 步內建立清單。
- 生成結果有分類、項目、重量與數量。
- Pro 範本在 MVP 先顯示鎖定狀態，不串接付費。

#### 3. 清單詳情頁

功能：

- Header 顯示清單名稱、總重、超重狀態。
- 分類可展開 / 收合。
- 項目可勾選、編輯名稱、重量、數量。
- 支援新增項目。
- 支援拖曳排序。
- 重量條即時更新。

驗收：

- 任一項目變更後總重立即更新。
- 超重時顯示明確狀態與提醒。
- 勾選進度與清單卡片一致。

#### 4. 重量系統與智慧減重

功能：

- 以 gram 作為內部唯一重量單位。
- 顯示層依 kg / g 設定轉換。
- 找出最重項目。
- 根據必要性與重量給出減重建議。
- 接近上限、超重時顯示不同視覺狀態。

驗收：

- 所有重量計算有單元測試。
- 超重差額計算準確。
- 建議排序符合「先處理重且非必要項目」。

#### 5. 超輕量化打包

功能：

- 清單詳情可切換超輕量化打包。
- 非必要物品降低視覺權重。
- 可刪減項目被標記。
- 顯示最低可行重量。

驗收：

- 開關超輕量化打包不破壞清單資料。
- 最低可行重量使用純函式計算，並有測試。

### Phase 2：分享、設定與上架品質，約 2 至 3 週

功能：

- 我的頁：單位設定、我的範本、已購買項目佔位。
- 系統分享：分享清單摘要文字。
- 圖片分享：產生可分享到 LINE / IG 的分享卡。
- 空狀態、錯誤狀態、刪除確認、loading state。
- 基礎 accessibility：文字縮放、對比、觸控範圍。
- 離線資料備份策略。

驗收：

- iOS 與 Android 的分享流程都可用。
- 主要頁面在小螢幕與大螢幕不溢位。
- Flutter widget test 覆蓋主要頁面。
- 核心計算邏輯單元測試覆蓋。

### Phase 3：Beta 與商店上架，約 1 至 2 週

iOS：

- 設定 Bundle ID、App Icon、Launch Screen。
- 設定 signing 與 provisioning profile。
- 建立 App Store Connect app。
- 準備 App Privacy、截圖、描述、關鍵字。
- 上傳 TestFlight build。
- 修正 App Review 可能被問到的資料收集與付費說明。

Android：

- 設定 applicationId、app signing、release keystore。
- 產生 Android App Bundle。
- 建立 Google Play Console app。
- 準備 Data safety、截圖、描述、分級問卷。
- 上傳 internal testing build。

共同：

- 版本號與 build number 規則。
- 隱私政策與服務條款頁面。
- Crash reporting 與基礎 analytics。
- Release checklist。

驗收：

- TestFlight 可安裝。
- Google Play internal testing 可安裝。
- iOS / Android 版本功能一致。
- 無 debug banner、無明顯 placeholder 文案。

## 5. 後續商業功能計畫

### Phase 4：範本中心與內購，約 2 至 3 週

功能：

- 範本中心列表。
- 免費範本與 Pro 範本。
- 範本詳情與預覽。
- iOS StoreKit 與 Android Billing。
- 購買恢復。
- 已購買項目管理。

驗收：

- 免費使用者可使用基礎範本。
- 付費後可解鎖 Pro 範本。
- iOS / Android 都支援恢復購買。
- 付費失敗、取消、重複購買都有處理。

### Phase 5：裝備庫與專業 UL，約 3 至 4 週

功能：

- 裝備庫主頁。
- 新增、編輯、刪除裝備。
- 從裝備庫加入清單。
- 從清單收藏回裝備庫。
- Base Weight / Consumables / Worn Weight 分離。
- UL 等級改以 Base Weight 判定。
- 重量分佈視覺化。

驗收：

- 裝備庫與既有清單採 snapshot，不回溯改動歷史清單。
- Base Weight、Total Pack Weight、Worn Weight 計算準確。
- 重量分佈可切換總背重與基重。

### Phase 6：帳號、雲端同步與協作，約 5 至 8 週

功能：

- 登入。
- 雲端清單同步。
- 唯讀分享連結。
- Pro 協作清單。
- 邀請連結與 QR code。
- 成員角色：owner、editor、viewer。
- 項目認領與個人負重。
- 即時同步。

驗收：

- 離線編輯與同步衝突有明確策略。
- owner 才能建立協作清單。
- 被邀請者不需 Pro 也能加入。
- 多人同時編輯不會造成資料遺失。

## 6. 建議優先級

Must have for 1.0：

- 清單列表。
- 建立清單流程。
- 清單詳情與兩層分類。
- 本機儲存。
- 重量計算。
- 超重提醒。
- 超輕量化打包。
- 系統分享。
- iOS / Android 上架設定。

Should have for 1.0：

- 圖片分享卡。
- 拖曳排序。
- 範本中心入口與 Pro 鎖定展示。
- 我的頁與單位設定。
- Crash reporting。

Could have for 1.0：

- UL 升級彈窗。
- 等級進度頁。
- 進階動效。
- 多套分享卡樣式。

Won't have in 1.0：

- 雲端同步。
- 帳號系統。
- 內購。
- 裝備庫。
- 重量分佈圖。
- 多人協作。

## 7. 技術工作清單

Flutter app：

- 建立 routing：首頁、建立流程、詳情、範本中心、我的。
- 建立 state management。
- 建立 repository layer。
- 建立 local database schema。
- 建立 sample templates seed data。
- 建立 weight calculation domain service。
- 建立 share service。
- 建立 platform release config。

測試：

- Weight calculation unit tests。
- Template generation unit tests。
- List CRUD repository tests。
- Home page widget tests。
- Create flow widget tests。
- Detail page widget tests。
- iOS / Android smoke test。

設計：

- 補齊正式首頁。
- 補齊建立流程。
- 補齊清單詳情。
- 補齊空狀態與錯誤狀態。
- 補齊 App Icon 與 Launch Screen。
- 補齊商店截圖。

營運與上架：

- App Store Connect 設定。
- Google Play Console 設定。
- 隱私政策。
- 服務條款。
- 商店文案。
- Beta 測試名單。

## 8. 里程碑建議

第 1 週：

- 完成資料模型、routing、local storage 選型。
- 將 app 入口改成首頁。
- 完成首頁空狀態與 sample list。

第 2 至 3 週：

- 完成建立清單流程。
- 完成範本 seed data。
- 完成清單生成邏輯。

第 4 至 5 週：

- 完成清單詳情、分類收合、項目編輯。
- 完成重量計算與超重提醒。
- 完成超輕量化打包。

第 6 週：

- 完成分享、我的頁、單位設定。
- 補齊測試。
- 做第一輪內部測試。

第 7 週：

- 修正 beta 問題。
- 完成 App Icon、Launch Screen、商店素材。
- 上傳 TestFlight 與 Google Play internal testing。

第 8 週：

- 修正平台審核與 beta 回饋。
- 準備 1.0 正式上架。

## 9. 主要風險與處理方式

範圍過大：

- 1.0 嚴格排除雲端、內購、協作，先驗證核心工具價值。

資料模型反覆修改：

- 一開始就以 gram 作為內部單位。
- 清單項目預留 `quantity`、`sortOrder`、`categoryId`、`necessity`。
- v2 要導入 Base Weight 時再新增 `weightClass`。

雙平台審核差異：

- 先做沒有帳號、沒有付費的 MVP，降低審核風險。
- 等 1.0 穩定後再加入內購。

分享圖片生成成本：

- 1.0 可先做文字分享。
- 圖片分享若工期不足，移到 1.1。

## 10. 1.0 完成定義

1. 使用者可從零建立一份打包清單。
2. 使用者可編輯項目、重量、數量與勾選狀態。
3. App 能即時計算重量、進度、超重狀態。
4. 超輕量化打包能提出可刪減項目與最低可行重量。
5. 使用者可分享清單摘要。
6. iOS 與 Android 都通過 beta 安裝測試。
7. App 可提交 App Store 與 Google Play 審核。
