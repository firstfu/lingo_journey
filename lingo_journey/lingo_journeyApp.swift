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
