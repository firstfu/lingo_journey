# i18n Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement full internationalization support for Lingo Journey with 9 languages and instant language switching.

**Architecture:** Observable LanguageManager singleton + Apple String Catalogs (.xcstrings) + SwiftUI environment locale injection.

**Tech Stack:** SwiftUI, @Observable, @AppStorage, String Catalogs, Locale

---

## Task 1: Create LanguageManager

**Files:**
- Create: `lingo_journey/Core/Services/LanguageManager.swift`

**Step 1: Create LanguageManager.swift**

```swift
import SwiftUI

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    enum AppLanguage: String, CaseIterable, Identifiable {
        case system = "system"
        case zhHant = "zh-Hant"
        case zhHans = "zh-Hans"
        case en = "en"
        case ja = "ja"
        case ko = "ko"
        case es = "es"
        case fr = "fr"
        case de = "de"
        case pt = "pt"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return String(localized: "settings.followSystem")
            case .zhHant: return "繁體中文"
            case .zhHans: return "简体中文"
            case .en: return "English"
            case .ja: return "日本語"
            case .ko: return "한국어"
            case .es: return "Español"
            case .fr: return "Français"
            case .de: return "Deutsch"
            case .pt: return "Português"
            }
        }
    }

    private let userDefaultsKey = "appLanguage"

    var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: userDefaultsKey)
        }
    }

    var currentLocale: Locale {
        if selectedLanguage == .system {
            return .current
        }
        return Locale(identifier: selectedLanguage.rawValue)
    }

    var currentLanguageDisplayName: String {
        if selectedLanguage == .system {
            let systemLang = Locale.current.language.languageCode?.identifier ?? "en"
            return AppLanguage(rawValue: systemLang)?.displayName ?? Locale.current.localizedString(forIdentifier: systemLang) ?? systemLang
        }
        return selectedLanguage.displayName
    }

    private init() {
        let savedValue = UserDefaults.standard.string(forKey: userDefaultsKey) ?? AppLanguage.system.rawValue
        self.selectedLanguage = AppLanguage(rawValue: savedValue) ?? .system
    }
}
```

**Step 2: Verify file created**

Run: `ls -la lingo_journey/Core/Services/LanguageManager.swift`

**Step 3: Commit**

```bash
git add lingo_journey/Core/Services/LanguageManager.swift
git commit -m "feat(i18n): add LanguageManager for language switching"
```

---

## Task 2: Create String Catalog

**Files:**
- Create: `lingo_journey/Resources/Localizable.xcstrings`

**Step 1: Create Resources directory**

```bash
mkdir -p lingo_journey/Resources
```

**Step 2: Create Localizable.xcstrings**

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "tab.translate" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Translate" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "翻譯" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "翻译" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "翻訳" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "번역" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Traducir" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Traduire" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Übersetzen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Traduzir" } }
      }
    },
    "tab.voice" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Voice" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "語音" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "语音" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "音声" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "음성" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Voz" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Voix" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Stimme" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Voz" } }
      }
    },
    "tab.history" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "History" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "歷史" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "历史" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "履歴" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "기록" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Historial" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Historique" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Verlauf" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Histórico" } }
      }
    },
    "tab.settings" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "設定" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "设置" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "設定" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "설정" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Ajustes" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Réglages" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Einstellungen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Configurações" } }
      }
    },
    "translation.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Translate" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "翻譯" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "翻译" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "翻訳" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "번역" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Traducir" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Traduire" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Übersetzen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Traduzir" } }
      }
    },
    "translation.button" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Translate" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "翻譯" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "翻译" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "翻訳する" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "번역하기" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Traducir" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Traduire" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Übersetzen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Traduzir" } }
      }
    },
    "settings.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "設定" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "设置" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "設定" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "설정" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Ajustes" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Réglages" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Einstellungen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Configurações" } }
      }
    },
    "settings.languages" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "LANGUAGES" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "語言" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "语言" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "言語" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "언어" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "IDIOMAS" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "LANGUES" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "SPRACHEN" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "IDIOMAS" } }
      }
    },
    "settings.appLanguage" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "App Language" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "App 語言" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "App 语言" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "アプリの言語" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "앱 언어" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Idioma de la app" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Langue de l'app" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "App-Sprache" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Idioma do app" } }
      }
    },
    "settings.followSystem" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Follow System" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "跟隨系統" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "跟随系统" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "システムに従う" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "시스템 설정 따르기" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Seguir sistema" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Suivre le système" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "System folgen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Seguir sistema" } }
      }
    },
    "settings.offlineLanguages" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Offline Languages" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "離線語言" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "离线语言" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "オフライン言語" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "오프라인 언어" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Idiomas sin conexión" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Langues hors ligne" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Offline-Sprachen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Idiomas offline" } }
      }
    },
    "settings.offlineLanguages.subtitle" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Download languages for offline use" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "下載語言以供離線使用" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "下载语言以供离线使用" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "オフラインで使用する言語をダウンロード" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "오프라인 사용을 위해 언어 다운로드" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Descargar idiomas para uso sin conexión" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Télécharger des langues pour une utilisation hors ligne" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Sprachen für Offline-Nutzung herunterladen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Baixar idiomas para uso offline" } }
      }
    },
    "settings.location" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "LOCATION" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "位置" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "位置" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "位置情報" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "위치" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "UBICACIÓN" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "LOCALISATION" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "STANDORT" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "LOCALIZAÇÃO" } }
      }
    },
    "settings.geoAware" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Geo-Aware Suggestions" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "地理感知建議" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "地理感知建议" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "位置情報に基づく提案" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "위치 기반 추천" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Sugerencias por ubicación" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Suggestions géolocalisées" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Standortbasierte Vorschläge" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Sugestões por localização" } }
      }
    },
    "settings.geoAware.subtitle" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Suggest languages based on your location" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "根據您的位置建議語言" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "根据您的位置建议语言" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "現在地に基づいて言語を提案" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "위치에 따라 언어 추천" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Sugerir idiomas según tu ubicación" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Suggérer des langues selon votre position" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Sprachen basierend auf Standort vorschlagen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Sugerir idiomas com base na sua localização" } }
      }
    },
    "settings.currentRegion" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Current Region" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "目前地區" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "当前地区" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "現在の地域" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "현재 지역" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Región actual" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Région actuelle" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Aktuelle Region" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Região atual" } }
      }
    },
    "settings.about" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "ABOUT" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "關於" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "关于" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "情報" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "정보" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "ACERCA DE" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "À PROPOS" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "ÜBER" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "SOBRE" } }
      }
    },
    "settings.version" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Version" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "版本" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "版本" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "バージョン" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "버전" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Versión" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Version" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Version" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Versão" } }
      }
    },
    "settings.privacyPolicy" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Privacy Policy" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "隱私權政策" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "隐私政策" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "プライバシーポリシー" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "개인정보 처리방침" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Política de privacidad" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Politique de confidentialité" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Datenschutz" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Política de privacidade" } }
      }
    },
    "history.title" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "History" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "歷史" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "历史" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "履歴" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "기록" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Historial" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Historique" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Verlauf" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Histórico" } }
      }
    },
    "history.searchPlaceholder" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Search translations..." } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "搜尋翻譯..." } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "搜索翻译..." } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "翻訳を検索..." } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "번역 검색..." } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Buscar traducciones..." } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Rechercher des traductions..." } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Übersetzungen suchen..." } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Pesquisar traduções..." } }
      }
    },
    "history.all" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "All" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "全部" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "全部" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "すべて" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "전체" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Todo" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Tout" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Alle" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Tudo" } }
      }
    },
    "history.favorites" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Favorites" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "收藏" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "收藏" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "お気に入り" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "즐겨찾기" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Favoritos" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Favoris" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Favoriten" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Favoritos" } }
      }
    },
    "history.delete" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Delete" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "刪除" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "删除" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "削除" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "삭제" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Eliminar" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Supprimer" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Löschen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Excluir" } }
      }
    },
    "history.favorite" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Favorite" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "收藏" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "收藏" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "お気に入りに追加" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "즐겨찾기 추가" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Favorito" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Favori" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Favorit" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Favorito" } }
      }
    },
    "history.unfavorite" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Unfavorite" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "取消收藏" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "取消收藏" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "お気に入りから削除" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "즐겨찾기 해제" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Quitar favorito" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Retirer des favoris" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Aus Favoriten entfernen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Remover favorito" } }
      }
    },
    "history.empty" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No translation history" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "沒有翻譯歷史" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "没有翻译历史" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "翻訳履歴がありません" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "번역 기록 없음" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Sin historial de traducción" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Aucun historique de traduction" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Kein Übersetzungsverlauf" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Sem histórico de tradução" } }
      }
    },
    "history.emptySubtitle" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Your translations will appear here" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "您的翻譯將顯示在這裡" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "您的翻译将显示在这里" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "翻訳がここに表示されます" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "번역이 여기에 표시됩니다" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Tus traducciones aparecerán aquí" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Vos traductions apparaîtront ici" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Ihre Übersetzungen werden hier angezeigt" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Suas traduções aparecerão aqui" } }
      }
    },
    "history.noFavorites" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "No favorites yet" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "尚無收藏" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "暂无收藏" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "お気に入りはまだありません" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "즐겨찾기 없음" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Sin favoritos aún" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Pas encore de favoris" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Noch keine Favoriten" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Nenhum favorito ainda" } }
      }
    },
    "history.noFavoritesSubtitle" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Star translations to save them here" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "將翻譯加入收藏以保存在這裡" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "将翻译加入收藏以保存在这里" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "翻訳にスターを付けてここに保存" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "별표를 눌러 여기에 저장하세요" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Marca traducciones para guardarlas aquí" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Ajoutez des traductions aux favoris pour les enregistrer ici" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Übersetzungen markieren, um sie hier zu speichern" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Favorite traduções para salvá-las aqui" } }
      }
    },
    "conversation.tapToSpeak" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Tap mic to speak" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "點擊麥克風說話" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "点击麦克风说话" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "マイクをタップして話す" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "마이크를 눌러 말하기" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Toca el micrófono para hablar" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Appuyez sur le micro pour parler" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Mikrofon antippen zum Sprechen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Toque no microfone para falar" } }
      }
    },
    "onboarding.title1" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Translate With Confidence" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "自信地翻譯" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "自信地翻译" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "自信を持って翻訳" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "자신있게 번역하세요" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Traduce con confianza" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Traduisez en toute confiance" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Mit Vertrauen übersetzen" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Traduza com confiança" } }
      }
    },
    "onboarding.description1" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Instantly understand and communicate in any language with ease." } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "輕鬆即時理解並使用任何語言溝通。" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "轻松即时理解并使用任何语言沟通。" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "あらゆる言語を瞬時に理解し、簡単にコミュニケーション。" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "어떤 언어든 즉시 이해하고 쉽게 소통하세요." } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Comprende y comunícate instantáneamente en cualquier idioma con facilidad." } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Comprenez et communiquez instantanément dans n'importe quelle langue." } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Verstehen und kommunizieren Sie sofort in jeder Sprache." } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Entenda e comunique-se instantaneamente em qualquer idioma." } }
      }
    },
    "onboarding.title2" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Face-to-Face Conversations" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "面對面對話" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "面对面对话" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "対面での会話" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "대면 대화" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Conversaciones cara a cara" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Conversations en face à face" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Persönliche Gespräche" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Conversas presenciais" } }
      }
    },
    "onboarding.description2" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Have natural conversations with anyone, regardless of language barriers." } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "與任何人自然對話，不受語言障礙限制。" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "与任何人自然对话，不受语言障碍限制。" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "言語の壁を越えて、誰とでも自然に会話。" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "언어 장벽 없이 누구와도 자연스럽게 대화하세요." } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Mantén conversaciones naturales con cualquiera, sin barreras idiomáticas." } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Ayez des conversations naturelles avec n'importe qui, sans barrière linguistique." } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Führen Sie natürliche Gespräche mit jedem, unabhängig von Sprachbarrieren." } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Tenha conversas naturais com qualquer pessoa, sem barreiras linguísticas." } }
      }
    },
    "onboarding.title3" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Works Offline" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "離線可用" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "离线可用" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "オフラインで動作" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "오프라인 작동" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Funciona sin conexión" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Fonctionne hors ligne" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Funktioniert offline" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Funciona offline" } }
      }
    },
    "onboarding.description3" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Download languages to translate anywhere, even without internet." } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "下載語言，隨時隨地翻譯，即使沒有網路。" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "下载语言，随时随地翻译，即使没有网络。" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "言語をダウンロードして、インターネットなしでも翻訳。" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "언어를 다운로드하여 인터넷 없이도 번역하세요." } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Descarga idiomas para traducir en cualquier lugar, incluso sin internet." } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Téléchargez des langues pour traduire partout, même sans internet." } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Laden Sie Sprachen herunter, um überall zu übersetzen, auch ohne Internet." } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Baixe idiomas para traduzir em qualquer lugar, mesmo sem internet." } }
      }
    },
    "onboarding.next" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Next" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "下一步" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "下一步" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "次へ" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "다음" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Siguiente" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Suivant" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Weiter" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Próximo" } }
      }
    },
    "onboarding.getStarted" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Get Started" } },
        "zh-Hant" : { "stringUnit" : { "state" : "translated", "value" : "開始使用" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "开始使用" } },
        "ja" : { "stringUnit" : { "state" : "translated", "value" : "始める" } },
        "ko" : { "stringUnit" : { "state" : "translated", "value" : "시작하기" } },
        "es" : { "stringUnit" : { "state" : "translated", "value" : "Comenzar" } },
        "fr" : { "stringUnit" : { "state" : "translated", "value" : "Commencer" } },
        "de" : { "stringUnit" : { "state" : "translated", "value" : "Los geht's" } },
        "pt" : { "stringUnit" : { "state" : "translated", "value" : "Começar" } }
      }
    }
  },
  "version" : "1.0"
}
```

**Step 3: Commit**

```bash
git add lingo_journey/Resources/Localizable.xcstrings
git commit -m "feat(i18n): add String Catalog with 9 languages"
```

---

## Task 3: Create LanguageSettingsView

**Files:**
- Create: `lingo_journey/Features/Settings/LanguageSettingsView.swift`

**Step 1: Create LanguageSettingsView.swift**

```swift
import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    ForEach(LanguageManager.AppLanguage.allCases) { language in
                        LanguageRow(
                            language: language,
                            isSelected: languageManager.selectedLanguage == language,
                            onTap: {
                                languageManager.selectedLanguage = language
                            }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.xl)
            }
        }
        .navigationTitle(String(localized: "settings.appLanguage"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LanguageRow: View {
    let language: LanguageManager.AppLanguage
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(language.displayName)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
            }
            .padding(AppSpacing.xl)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/Settings/LanguageSettingsView.swift
git commit -m "feat(i18n): add LanguageSettingsView for language selection"
```

---

## Task 4: Update lingo_journeyApp.swift

**Files:**
- Modify: `lingo_journey/lingo_journeyApp.swift`

**Step 1: Update App entry point to inject locale**

Replace entire file content:

```swift
//
//  lingo_journeyApp.swift
//  lingo_journey
//
//  Created by firstfu on 2026/1/27.
//

import SwiftUI
import SwiftData

@main
struct lingo_journeyApp: App {
    @State private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, languageManager.currentLocale)
                .environment(languageManager)
        }
        .modelContainer(for: [
            TranslationRecord.self,
            LanguagePackage.self
        ])
    }
}
```

**Step 2: Commit**

```bash
git add lingo_journey/lingo_journeyApp.swift
git commit -m "feat(i18n): inject locale environment in App entry"
```

---

## Task 5: Update MainTabView.swift

**Files:**
- Modify: `lingo_journey/Features/MainTabView.swift`

**Step 1: Replace hardcoded strings with localized keys**

Replace entire file content:

```swift
import SwiftUI

enum AppTab: Int, CaseIterable {
    case translate
    case voice
    case history
    case settings

    var titleKey: LocalizedStringKey {
        switch self {
        case .translate: return "tab.translate"
        case .voice: return "tab.voice"
        case .history: return "tab.history"
        case .settings: return "tab.settings"
        }
    }

    var icon: String {
        switch self {
        case .translate: return "character.bubble"
        case .voice: return "waveform"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .translate

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.titleKey, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(.appPrimary)
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .translate:
            TranslationView()
        case .voice:
            ConversationView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/MainTabView.swift
git commit -m "feat(i18n): localize MainTabView tab titles"
```

---

## Task 6: Update SettingsView.swift

**Files:**
- Modify: `lingo_journey/Features/Settings/SettingsView.swift`

**Step 1: Add language settings section and localize strings**

Replace entire file content:

```swift
import SwiftUI

struct SettingsView: View {
    @State private var locationService = LocationService()
    @State private var languageManager = LanguageManager.shared
    @State private var isGeoAwareEnabled = true
    @State private var showLanguagePackages = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xxl) {
                        Text("settings.title")
                            .font(.appTitle1)
                            .foregroundColor(.appTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppSpacing.xl)

                        SettingsSection(title: String(localized: "settings.languages")) {
                            NavigationLink {
                                LanguageSettingsView()
                            } label: {
                                HStack(spacing: AppSpacing.lg) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 20))
                                        .foregroundColor(.appPrimary)
                                        .frame(width: 28)

                                    Text("settings.appLanguage")
                                        .font(.appBody)
                                        .foregroundColor(.appTextPrimary)

                                    Spacer()

                                    Text(languageManager.currentLanguageDisplayName)
                                        .font(.appBody)
                                        .foregroundColor(.appTextMuted)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.appTextMuted)
                                }
                                .padding(AppSpacing.xl)
                            }

                            SettingsRow(
                                icon: "arrow.down.circle",
                                title: String(localized: "settings.offlineLanguages"),
                                subtitle: String(localized: "settings.offlineLanguages.subtitle")
                            ) {
                                showLanguagePackages = true
                            }
                        }

                        SettingsSection(title: String(localized: "settings.location")) {
                            SettingsToggleRow(
                                icon: "location",
                                title: String(localized: "settings.geoAware"),
                                subtitle: String(localized: "settings.geoAware.subtitle"),
                                isOn: $isGeoAwareEnabled
                            )

                            if let countryCode = locationService.countryCode {
                                SettingsInfoRow(
                                    icon: "globe",
                                    title: String(localized: "settings.currentRegion"),
                                    value: countryCode
                                )
                            }
                        }

                        SettingsSection(title: String(localized: "settings.about")) {
                            SettingsInfoRow(
                                icon: "info.circle",
                                title: String(localized: "settings.version"),
                                value: "1.0.0"
                            )

                            SettingsRow(
                                icon: "hand.raised",
                                title: String(localized: "settings.privacyPolicy"),
                                subtitle: nil
                            ) {
                                // Open privacy policy
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.xxl)
                }
            }
            .sheet(isPresented: $showLanguagePackages) {
                LanguagePackagesView()
            }
            .onChange(of: isGeoAwareEnabled) { _, enabled in
                if enabled {
                    Task {
                        _ = await locationService.requestAuthorization()
                        await locationService.refresh()
                    }
                }
            }
            .task {
                if isGeoAwareEnabled {
                    await locationService.initialize()
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(title.uppercased())
                .font(.appCaption)
                .foregroundColor(.appTextMuted)
                .padding(.horizontal, AppSpacing.xl)

            VStack(spacing: 1) {
                content()
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
            .padding(.horizontal, AppSpacing.xl)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.appPrimary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.appFootnote)
                            .foregroundColor(.appTextMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextMuted)
            }
            .padding(AppSpacing.xl)
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)

                Text(subtitle)
                    .font(.appFootnote)
                    .foregroundColor(.appTextMuted)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.appPrimary)
        }
        .padding(AppSpacing.xl)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appPrimary)
                .frame(width: 28)

            Text(title)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)

            Spacer()

            Text(value)
                .font(.appBody)
                .foregroundColor(.appTextMuted)
        }
        .padding(AppSpacing.xl)
    }
}

#Preview {
    SettingsView()
}
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/Settings/SettingsView.swift
git commit -m "feat(i18n): localize SettingsView and add language settings"
```

---

## Task 7: Update TranslationView.swift

**Files:**
- Modify: `lingo_journey/Features/Translation/TranslationView.swift`

**Step 1: Localize hardcoded strings**

In TranslationView.swift, replace:
- Line 21: `Text("Translate")` → `Text("translation.title")`
- Line 41: `title: "Translate"` → `title: String(localized: "translation.button")`

**Step 2: Commit**

```bash
git add lingo_journey/Features/Translation/TranslationView.swift
git commit -m "feat(i18n): localize TranslationView"
```

---

## Task 8: Update HistoryView.swift

**Files:**
- Modify: `lingo_journey/Features/History/HistoryView.swift`

**Step 1: Localize hardcoded strings**

Key replacements:
- Line 33: `Text("History")` → `Text("history.title")`
- Line 45: `Text("All")` → `Text("history.all")`
- Line 46: `Text("Favorites")` → `Text("history.favorites")`
- Line 66: `Label("Delete"...)` → `Label(String(localized: "history.delete")...)`
- Line 73-74: favorite/unfavorite labels
- Line 106: search placeholder
- Line 181: empty state titles
- Line 185: empty state subtitles

**Step 2: Commit**

```bash
git add lingo_journey/Features/History/HistoryView.swift
git commit -m "feat(i18n): localize HistoryView"
```

---

## Task 9: Update ConversationView.swift

**Files:**
- Modify: `lingo_journey/Features/Conversation/ConversationView.swift`

**Step 1: Localize "Tap mic to speak"**

Line 176: `Text("Tap mic to speak")` → `Text("conversation.tapToSpeak")`

**Step 2: Commit**

```bash
git add lingo_journey/Features/Conversation/ConversationView.swift
git commit -m "feat(i18n): localize ConversationView"
```

---

## Task 10: Update OnboardingView.swift

**Files:**
- Modify: `lingo_journey/Features/Onboarding/OnboardingView.swift`

**Step 1: Refactor to use localized strings**

Replace entire file with localized version using String(localized:) for title/description and onboarding button text.

**Step 2: Commit**

```bash
git add lingo_journey/Features/Onboarding/OnboardingView.swift
git commit -m "feat(i18n): localize OnboardingView"
```

---

## Task 11: Final Integration Test

**Step 1: Build and verify**

```bash
xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -configuration Debug build
```

**Step 2: Final commit with all changes**

```bash
git add .
git commit -m "feat(i18n): complete internationalization implementation

- Add LanguageManager for language switching
- Add String Catalog with 9 languages
- Add LanguageSettingsView
- Localize all UI strings
- Support instant language switching"
```

---

## Summary

| Task | Component | Files Changed |
|------|-----------|---------------|
| 1 | LanguageManager | 1 new |
| 2 | String Catalog | 1 new |
| 3 | LanguageSettingsView | 1 new |
| 4 | App Entry | 1 modified |
| 5 | MainTabView | 1 modified |
| 6 | SettingsView | 1 modified |
| 7 | TranslationView | 1 modified |
| 8 | HistoryView | 1 modified |
| 9 | ConversationView | 1 modified |
| 10 | OnboardingView | 1 modified |
| 11 | Integration Test | - |

**Total: 3 new files, 7 modified files**
