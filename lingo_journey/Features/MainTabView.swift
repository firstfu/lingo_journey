import SwiftUI

// Environment key for triggering language packages sheet
private struct ShouldOpenLanguagePackagesKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var shouldOpenLanguagePackages: Binding<Bool> {
        get { self[ShouldOpenLanguagePackagesKey.self] }
        set { self[ShouldOpenLanguagePackagesKey.self] = newValue }
    }
}

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
    @State private var shouldOpenLanguagePackages = false

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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToLanguagePackages)) { _ in
            selectedTab = .settings
            shouldOpenLanguagePackages = true
        }
        .environment(\.shouldOpenLanguagePackages, $shouldOpenLanguagePackages)
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
