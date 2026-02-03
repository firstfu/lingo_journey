//
//  lingo_journeyApp.swift
//  lingo_journey
//
//  Created by firstfu on 2026/1/27.
//

import AVFoundation
import SwiftData
import SwiftUI

@main
struct lingo_journeyApp: App {
    @State private var languageManager = LanguageManager.shared

    init() {
        configureAudioSession()
    }

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

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothA2DP, .mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
