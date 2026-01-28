//
//  lingo_journeyApp.swift
//  lingo_journey
//
//  Created by firstfu on 2026/1/27.
//

import SwiftUI
import SwiftData
import Translation

@main
struct lingo_journeyApp: App {
    @State private var languageManager = LanguageManager.shared
    @State private var clipboardService = ClipboardTranslationService.shared
    private let liveActivityManager = LiveActivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, languageManager.currentLocale)
                .environment(languageManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .task {
                    // App 啟動時，如果常駐模式開啟，恢復動態島
                    if liveActivityManager.isPersistentEnabled {
                        liveActivityManager.startPersistentActivity()
                    }
                }
                .translationTask(clipboardService.translationConfiguration) { session in
                    await clipboardService.performTranslation(session: session)
                }
        }
        .modelContainer(for: [
            TranslationRecord.self,
            LanguagePackage.self
        ])
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "lingojourney" else { return }

        switch url.host {
        case "translate-clipboard":
            Task {
                await clipboardService.prepareClipboardTranslation()
            }
        default:
            break
        }
    }
}
