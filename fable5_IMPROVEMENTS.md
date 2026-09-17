# PackPlan 安全與品質改善清單

來源：2026-07-06 全 codebase 安全/品質檢視。
大項(字型連網、匯入大小檢查、寫入失敗靜默)已完成,本檔記錄剩餘小項,
處理完請勾選並註記日期。

## 已完成(紀錄)

- [x] **google_fonts 執行期連網抓字型** — 2026-07-06 改為本地打包
  `assets/fonts/`(Roboto 400/500 + Noto Sans TC 繁中子集 400/500),
  移除 google_fonts 依賴。離線可用,Android 無 INTERNET 權限也不受影響。
- [x] **匯入備份先整檔載入才檢查大小** — 2026-07-06 改為先用 `file.size`
  metadata 擋掉超過 10 MB 的檔案,通過後才讀進記憶體
  (`lib/screens/profile_screen.dart` `_importBackup`)。
- [x] **SQLite 寫入失敗使用者無感** — 2026-07-06 新增 `hasSaveError` 狀態與
  AppShell 紅底警示橫幅,失敗期間持續顯示、恢復自動消失,含 2 個自動化測試。

## 待辦小項

### 1. 備份數值缺上限(安全/穩健性,低風險)

- **位置**:`lib/services/backup_codec.dart`
- **問題**:`weightGram`、`quantity`、`days` 等欄位只驗證正數/非負,
  沒有上限。精心構造的備份檔可以塞極大值(如 2⁶²),重量加總可能溢位、
  UI 顯示荒謬數字。
- **建議**:在 `_decodeItem` / `_decodeList` 加合理上限,例如:
  - 單件重量 ≤ 999,999 g(約 1 噸)
  - 數量 ≤ 999
  - 天數/晚數 ≤ 365
  - 重量上限 ≤ 999,999 g
  超過就丟 `BackupFormatException('… 超出合理範圍')`。
  記得同步加 unit test(`test/backup_codec_test.dart`)。

### 2. `on Object` 吞掉所有錯誤(可觀測性)

- **位置**:`lib/screens/profile_screen.dart` 的 `_exportBackup`、
  `_importBackup`;`lib/main.dart` 的 `catch (_)`。
- **問題**:catch-all 對 UX 沒問題,但真正的程式 bug(非格式錯誤)也會
  被吞掉,只剩一句「請稍後再試」,除錯時完全沒線索。
- **建議**:catch-all 分支裡加 `FlutterError.reportError(...)`
  (參考 `persistent_pack_list_repository.dart` `_queueSave` 的寫法),
  之後接 crash reporting(L 節 P1)時這些錯誤就能自動上報。

### 3. `lime*` 舊色名清理(程式碼衛生)

- **位置**:`lib/theme/app_colors.dart` 底部
  (`limE50` / `lime100` / `lime300` / `lime500` / `lime700` / `lime900`)。
- **問題**:配色已從 v4 萊姆綠改為 v5 橘色,這些別名只是指向
  `orange*` 的舊名,還有一個 `limE50` 大小寫 typo。留著會誤導後續開發。
- **建議**:全域搜尋 `lime` 把引用處改成對應的 `orange*` 常數,
  然後刪掉整段別名。純機械性重構,改完跑 `flutter analyze` + 測試即可。

### 4. `ITSAppUsesNonExemptEncryption` 未設定(上架流程)

- **位置**:`ios/Runner/Info.plist`
- **問題**:沒設這個 key 的話,每次上傳 TestFlight 都要手動回答
  出口加密合規問卷。
- **建議**:App 只用 HTTPS/系統標準加密(甚至沒有網路功能),
  屬於豁免範圍,直接加:

  ```xml
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
  ```

### 5. `android:label="packplan"` 全小寫(上架檢查)

- **位置**:`android/app/src/main/AndroidManifest.xml`
- **問題**:安裝後桌面顯示的 App 名稱是小寫 `packplan`。
- **建議**:改成正式名稱(如 `PackPlan`);與 QUALITY_ACCEPTANCE.md
  L 節「App 名稱、Bundle ID、applicationId 正確」同時處理。

### 6. 每次變更全量序列化(效能,規模大才會浮現)

- **位置**:`lib/data/persistent_pack_list_repository.dart`
  `_handleChange` → `_snapshot()`
- **問題**:每勾一個 checkbox 就把「全部清單」encode 成 JSON 再整包寫入
  SQLite,而且在 main isolate 上執行。F 節 P1 有「100 份清單」驗收項,
  到那個量級每次點擊都可能掉幀。
- **建議**(擇一或並用):
  - 加 debounce(約 300ms),連續操作只寫最後一次;
    注意要保證 App 進背景前 flush。
  - 把 `BackupCodec.encode` 移到 `compute()` isolate。
  - 先在 100 份清單的情境實測,沒有明顯卡頓就維持現狀
    (簡單性也是價值)。

### 7. Release 簽章(已列 L 節,此處僅提醒)

- **位置**:`android/app/build.gradle.kts`(`signingConfig` 用 debug)、
  iOS signing/provisioning。
- **說明**:debug keystore 是公開的,正式發佈前必須換 release keystore;
  iOS Archive 也要等 signing 完成後重新驗證(A 節該項目前未勾)。
  依 QUALITY_ACCEPTANCE.md L 節處理即可,不重複展開。

## 建議處理順序

1 和 2 一起做(都在資料層,半小時內),3 純機械性隨時可做,
4、5、7 併入上架前 L 節一次處理,6 等有 100 份清單的實測數據再決定。
