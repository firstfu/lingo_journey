# LingoJourney (語遊) - 設計規格文件

**專案名稱：** LingoJourney (語遊)
**版本：** v1.0 (2026 MVP)
**開發框架：** SwiftUI + Apple Intelligence (Translation Framework)
**建立日期：** 2026-01-27

---

## 1. 產品定位

### 目標用戶
- 頻繁跨國旅行者
- 背包客
- 商務出差人士

### 核心價值
利用 Apple Intelligence 提供零延遲、極高隱私、完全離線的翻譯體驗，解決旅途中網路不穩與溝通斷層的痛點。

---

## 2. 設計參考

**風格來源：** [Dribbble - Language Translator App](https://dribbble.com/shots/26794338-Language-Translator-App)

**設計特色：**
- Dark Mode + Minimalism
- 大圓角膠囊按鈕
- 深藍色系卡片
- 線性圖標 + 藍色強調
- 音波視覺化動畫

---

## 3. 色彩系統

### 主色調 (Dark Theme)

| Token | 色值 | 用途 |
|-------|------|------|
| `background` | `#0A1628` | App 主背景 |
| `surface` | `#0F2744` | 卡片、輸入框背景 |
| `surfaceElevated` | `#162D4A` | 浮動元素、Modal 背景 |
| `primary` | `#4A9EFF` | 主要按鈕、強調色、選中狀態 |
| `primaryMuted` | `#2563EB` | 按鈕 pressed 狀態 |
| `textPrimary` | `#FFFFFF` | 標題、重要文字 |
| `textSecondary` | `#8E9BAE` | 說明文字、placeholder |
| `textMuted` | `#5A6B7D` | 次要資訊、時間戳記 |
| `border` | `#1E3A5F` | 卡片邊框、分隔線 |
| `success` | `#10B981` | 下載完成、連線成功 |
| `warning` | `#F59E0B` | 離線提示、低電量 |
| `error` | `#EF4444` | 錯誤訊息、刪除動作 |

### SwiftUI 實作

```swift
import SwiftUI

extension Color {
    static let appBackground = Color(hex: "0A1628")
    static let appSurface = Color(hex: "0F2744")
    static let appSurfaceElevated = Color(hex: "162D4A")
    static let appPrimary = Color(hex: "4A9EFF")
    static let appPrimaryMuted = Color(hex: "2563EB")
    static let appTextPrimary = Color.white
    static let appTextSecondary = Color(hex: "8E9BAE")
    static let appTextMuted = Color(hex: "5A6B7D")
    static let appBorder = Color(hex: "1E3A5F")
    static let appSuccess = Color(hex: "10B981")
    static let appWarning = Color(hex: "F59E0B")
    static let appError = Color(hex: "EF4444")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

## 4. 字體系統

### 字體選擇

| 用途 | 字體 | 說明 |
|------|------|------|
| 英文/數字 | SF Pro | iOS 系統字體 |
| 中文 | PingFang TC | 系統自動回退 |
| 等寬數字 | SF Mono | 時間戳記、語言代碼 |

### 字級規範

| Token | 大小 | 字重 | 行高 | 用途 |
|-------|------|------|------|------|
| `largeTitle` | 34pt | Bold | 1.2 | Splash 標題 |
| `title1` | 28pt | Bold | 1.25 | 頁面標題 |
| `title2` | 22pt | Semibold | 1.3 | 區塊標題 |
| `headline` | 17pt | Semibold | 1.4 | 語言名稱 |
| `body` | 17pt | Regular | 1.5 | 翻譯結果文字 |
| `callout` | 16pt | Regular | 1.45 | 輸入框 placeholder |
| `subheadline` | 15pt | Regular | 1.4 | Tab Bar 標籤 |
| `footnote` | 13pt | Regular | 1.35 | 時間戳記 |
| `caption` | 12pt | Medium | 1.3 | Badge、標籤 |

### SwiftUI 實作

```swift
extension Font {
    static let appLargeTitle = Font.system(size: 34, weight: .bold)
    static let appTitle1 = Font.system(size: 28, weight: .bold)
    static let appTitle2 = Font.system(size: 22, weight: .semibold)
    static let appHeadline = Font.system(size: 17, weight: .semibold)
    static let appBody = Font.system(size: 17, weight: .regular)
    static let appCallout = Font.system(size: 16, weight: .regular)
    static let appSubheadline = Font.system(size: 15, weight: .regular)
    static let appFootnote = Font.system(size: 13, weight: .regular)
    static let appCaption = Font.system(size: 12, weight: .medium)
}
```

---

## 5. 間距與圓角

### 間距系統 (8pt Grid)

| Token | 值 | 用途 |
|-------|-----|------|
| `spacing2` | 2pt | 圖標與文字緊密間距 |
| `spacing4` | 4pt | 行內元素間距 |
| `spacing8` | 8pt | 緊湊元素間距 |
| `spacing12` | 12pt | 卡片內 padding |
| `spacing16` | 16pt | 標準間距 |
| `spacing20` | 20pt | 區塊間距 |
| `spacing24` | 24pt | 大型卡片內 padding |
| `spacing32` | 32pt | 區塊分隔 |
| `spacing48` | 48pt | 頁面頂部/底部 padding |

### 圓角系統

| Token | 值 | 用途 |
|-------|-----|------|
| `radiusSmall` | 8pt | 小按鈕、Badge |
| `radiusMedium` | 12pt | 輸入框、小卡片 |
| `radiusLarge` | 16pt | 標準卡片 |
| `radiusXL` | 20pt | 大型卡片、Modal |
| `radiusFull` | 9999pt | 膠囊按鈕 |

### SwiftUI 實作

```swift
struct AppSpacing {
    static let xs: CGFloat = 2
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 20
    static let xxxl: CGFloat = 24
    static let section: CGFloat = 32
    static let page: CGFloat = 48
}

struct AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 9999
}
```

---

## 6. 核心元件

### 按鈕樣式

| 類型 | 外觀 | 用途 |
|------|------|------|
| **Primary** | 背景 `#4A9EFF`、白字、膠囊形、高度 50pt | 主要 CTA |
| **Secondary** | 背景 `#0F2744`、藍字、膠囊形、1pt 藍邊框 | 次要操作 |
| **Ghost** | 透明背景、藍字 | 文字連結 |
| **Icon Button** | 44x44pt 觸控區、24pt 圖標 | Tab Bar |

### 語言選擇器

```
┌─────────────────────────────────────┐
│  [Bengali]  ⟷  [English]           │
└─────────────────────────────────────┘
```
- 膠囊形、背景 `surface`、邊框 `border`
- 中間交換按鈕可點擊切換語言方向

### 輸入卡片

```
┌─────────────────────────────────────┐
│ Bengali                        🎤   │
│ Enter your text here...             │
│                                     │
│─────────────────────────────────────│
│ [Aa Text] [📷 Image] [📄 Document] │
└─────────────────────────────────────┘
```
- 圓角 16pt、背景 `surface`

### 歷史紀錄卡片

```
┌─────────────────────────────────────┐
│ 🤖                               ⭐ │
│ "Hello, how are you?"               │
│ → "你好，你好嗎？"                   │
│                            10:30 AM │
└─────────────────────────────────────┘
```

---

## 7. 頁面結構

### App 導航流程

```
App Launch
    ↓
Splash Screen (1.5s)
    ↓
First Launch? ─── Yes ──→ Onboarding (3 頁) ─┐
    │                                         │
    └─── No ──→ Main Tab Bar ←────────────────┘
```

### Tab Bar 結構

| Tab | 圖標 | SF Symbol | 主要功能 |
|-----|------|-----------|----------|
| 翻譯 | 文字氣泡 | `character.bubble` | 文字輸入、相機入口 |
| 語音 | 音波 | `waveform` | 雙向即時對話 |
| 歷史 | 時鐘箭頭 | `clock.arrow.circlepath` | 紀錄、收藏、搜尋 |
| 設定 | 齒輪 | `gearshape` | 離線包、偏好設定 |

### 頁面層級

```
翻譯 Tab
├── 語言選擇器
├── 文字輸入卡片
├── 翻譯結果卡片
└── 輸入類型切換 (Text/Image/Document)
    └── Image → 相機/相簿 Sheet

語音 Tab (雙向對話)
├── 上半部：對方語言區
├── 中間：分隔線 + 語言標示
└── 下半部：我方語言區 + 麥克風按鈕

歷史 Tab
├── 搜尋列
├── Segmented: [全部] [收藏]
└── 翻譯紀錄列表
    └── 點擊 → 詳情頁

設定 Tab
├── 離線語言包管理 → 子頁面
├── 地理感知開關
├── 預設語言設定
└── 關於/隱私政策
```

---

## 8. 動態島與動畫

### Dynamic Island 整合

| 狀態 | 顯示內容 |
|------|----------|
| 收合狀態 | 語言圖示 + 小型音波動畫 |
| 展開狀態 | 來源語言 → 目標語言 + 即時文字預覽 |
| 最小狀態 | 脈動圓點表示翻譯進行中 |

### 動畫規格

| 動畫 | 時長 | 曲線 | 用途 |
|------|------|------|------|
| 頁面轉場 | 350ms | `easeInOut` | Tab 切換 |
| 按鈕回饋 | 150ms | `easeOut` | 點擊縮放 0.96 |
| 音波動畫 | 持續 | `linear` | 錄音視覺回饋 |
| 卡片出現 | 300ms | `spring(0.7)` | 翻譯結果顯示 |
| 收藏星號 | 200ms | `spring(0.6)` | 彈跳效果 |

### 觸覺回饋 (Haptics)

| 事件 | 回饋類型 |
|------|----------|
| 開始錄音 | `.impact(.medium)` |
| 翻譯完成 | `.notification(.success)` |
| 切換語言 | `.impact(.light)` |
| 錯誤發生 | `.notification(.error)` |
| 收藏操作 | `.impact(.light)` |

---

## 9. 技術架構

### 框架與 API

| 功能 | 框架/API |
|------|----------|
| UI 層 | SwiftUI (iOS 18+) |
| 翻譯核心 | Translation Framework |
| 語音辨識 | Speech Framework |
| 語音合成 | AVSpeechSynthesizer |
| 本地儲存 | SwiftData |
| 位置服務 | CoreLocation |
| 相機/OCR | VisionKit |
| 動態島 | ActivityKit |
| 背景處理 | BGTaskScheduler |

### 專案結構

```
LingoJourney/
├── App/
│   └── LingoJourneyApp.swift
├── Features/
│   ├── Translation/
│   ├── Conversation/
│   ├── History/
│   ├── Settings/
│   └── Onboarding/
├── Core/
│   ├── Services/
│   │   ├── TranslationService.swift
│   │   ├── SpeechService.swift
│   │   └── LocationService.swift
│   ├── Models/
│   └── Extensions/
├── DesignSystem/
│   ├── Colors.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   └── Components/
├── Resources/
│   └── Assets.xcassets
└── LiveActivity/
    └── TranslationActivityWidget.swift
```

### 資料模型 (SwiftData)

```swift
import SwiftData

@Model
class TranslationRecord {
    var id: UUID
    var sourceText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var isFavorite: Bool
    var createdAt: Date

    init(sourceText: String, translatedText: String,
         sourceLanguage: String, targetLanguage: String) {
        self.id = UUID()
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.isFavorite = false
        self.createdAt = Date()
    }
}

@Model
class LanguagePackage {
    var languageCode: String
    var displayName: String
    var isDownloaded: Bool
    var downloadedAt: Date?
    var fileSize: Int64

    init(languageCode: String, displayName: String, fileSize: Int64) {
        self.languageCode = languageCode
        self.displayName = displayName
        self.isDownloaded = false
        self.fileSize = fileSize
    }
}
```

---

## 10. MVP 功能範圍

### 功能清單

| 功能 | 優先級 | 階段 |
|------|--------|------|
| 文字輸入翻譯 | P0 | MVP |
| 語音輸入翻譯 | P0 | MVP |
| 雙向即時對話 | P0 | MVP |
| 離線語言包管理 | P0 | MVP |
| 地理感知語言推薦 | P1 | MVP |
| 翻譯歷史紀錄 | P1 | MVP |
| 收藏功能 | P1 | MVP |
| 關鍵字搜尋 | P1 | MVP |
| 動態島整合 | P2 | MVP |
| 相機翻譯 (OCR) | P3 | Phase 3 |
| iCloud 同步 | P3 | Phase 2 |
| AR 實境翻譯 | P4 | Phase 3 |

### 非功能性需求

| 維度 | 目標 |
|------|------|
| 隱私 | 所有翻譯優先在設備端完成 |
| 效能 | 語音→文字延遲 < 200ms |
| 支援系統 | iOS 18.0+ |
| 最佳化晶片 | A17 Pro / M3+ Neural Engine |

### 預估畫面數量

| 類型 | 數量 |
|------|------|
| Tab 主頁面 | 4 |
| 子頁面/Sheet | 5 |
| Modal/Alert | 3 |
| **總計** | **~12 個畫面** |

---

## 11. 發展路線圖

### Phase 1 (MVP)
- 基礎文字與語音翻譯
- 雙向即時對話模式
- 離線語言包管理
- 地理感知語言推薦
- 歷史紀錄 + 收藏 + 搜尋
- 動態島整合

### Phase 2
- SwiftData + iCloud 同步
- 翻譯品質回饋機制
- Widget 支援

### Phase 3
- VisionKit 相機翻譯
- AR 實境導覽翻譯
- 貨幣自動換算

---

*文件建立日期：2026-01-27*
*最後更新：2026-01-27*
