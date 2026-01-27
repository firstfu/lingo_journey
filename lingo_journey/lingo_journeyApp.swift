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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            TranslationRecord.self,
            LanguagePackage.self
        ])
    }
}
