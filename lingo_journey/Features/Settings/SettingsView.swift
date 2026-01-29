import SwiftUI

struct SettingsView: View {
    @State private var locationService = LocationService()
    @State private var languageManager = LanguageManager.shared
    @State private var isGeoAwareEnabled = true
    @State private var showLanguagePackages = false
    @Environment(\.shouldOpenLanguagePackages) private var shouldOpenLanguagePackages

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
                LanguagePickerSheet(
                    title: String(localized: "settings.offlineLanguages"),
                    dismissOnSelect: false
                ) { _, _ in
                    // 下載由 LanguagePickerSheet 內部處理
                }
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
            .onChange(of: shouldOpenLanguagePackages.wrappedValue) { _, shouldOpen in
                if shouldOpen {
                    showLanguagePackages = true
                    shouldOpenLanguagePackages.wrappedValue = false
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
