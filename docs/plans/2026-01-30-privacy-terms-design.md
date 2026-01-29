# 隱私權政策與使用條款設計

## 概述

在設定頁面新增「隱私權政策」和「使用條款」兩個內建頁面。

## 決策記錄

- **呈現方式**：App 內建頁面（非外部連結）
- **格式**：純文字列表（標題 + 段落）
- **資料處理**：完全離線，無資料上傳
- **聯絡信箱**：firefirstfu@gmail.com

## 檔案變更

### 新增檔案

1. `lingo_journey/Features/Settings/PrivacyPolicyView.swift`
2. `lingo_journey/Features/Settings/TermsOfServiceView.swift`

### 修改檔案

1. `lingo_journey/Features/Settings/SettingsView.swift` - 加入導覽連結
2. `lingo_journey/Resources/Localizable.xcstrings` - 新增多語系文字

## 頁面結構

兩個頁面使用相同佈局：
- 頂部標題
- 最後更新日期
- 多個段落（小標題 + 內文）
- 使用 `NavigationLink` 從設定頁面推進

## 隱私權政策內容

1. **簡介** - Lingo Journey 重視隱私，採用離線優先設計
2. **資料收集** - 不收集、不傳送任何個人資料到伺服器
3. **裝置端資料** - 翻譯歷史、語言偏好、收藏翻譯（僅存裝置）
4. **權限使用說明**
   - 位置：偵測地區建議語言，資料不離開裝置
   - 麥克風：語音輸入，辨識在裝置上進行
   - 相機：OCR 文字掃描，影像不離開裝置
5. **第三方服務** - 使用 Apple 內建框架，由 Apple 隱私政策規範
6. **資料刪除** - 可刪除歷史或移除 App 清除所有資料
7. **聯絡方式** - firefirstfu@gmail.com

## 使用條款內容

1. **接受條款** - 使用即表示同意
2. **服務說明** - 離線翻譯服務，依賴 Apple Translation 框架
3. **使用限制** - 個人非商業用途、不得違法使用、禁止逆向工程
4. **翻譯準確性免責** - 機器翻譯可能有誤，不適用於關鍵用途
5. **智慧財產權** - App 設計與程式碼歸開發者所有
6. **服務變更** - 保留修改或終止服務權利
7. **免責聲明** - 按現狀提供，不保證無錯誤
8. **條款修改** - 條款可能更新，繼續使用視為接受
9. **聯絡方式** - firefirstfu@gmail.com

## 多語系支援

需新增本地化字串（支援：zh-Hant, zh-Hans, en, ja, ko, es, fr, de, pt）：
- 頁面標題
- 最後更新日期
- 各段落標題與內文
