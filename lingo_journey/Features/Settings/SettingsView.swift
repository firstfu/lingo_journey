import SwiftUI

struct SettingsView: View {
    @State private var locationService = LocationService()
    @State private var isGeoAwareEnabled = true
    @State private var showLanguagePackages = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    Text("Settings")
                        .font(.appTitle1)
                        .foregroundColor(.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.xl)

                    SettingsSection(title: "Languages") {
                        SettingsRow(
                            icon: "arrow.down.circle",
                            title: "Offline Languages",
                            subtitle: "Download languages for offline use"
                        ) {
                            showLanguagePackages = true
                        }
                    }

                    SettingsSection(title: "Location") {
                        SettingsToggleRow(
                            icon: "location",
                            title: "Geo-Aware Suggestions",
                            subtitle: "Suggest languages based on your location",
                            isOn: $isGeoAwareEnabled
                        )

                        if let countryCode = locationService.currentCountryCode {
                            SettingsInfoRow(
                                icon: "globe",
                                title: "Current Region",
                                value: countryCode
                            )
                        }
                    }

                    SettingsSection(title: "About") {
                        SettingsInfoRow(
                            icon: "info.circle",
                            title: "Version",
                            value: "1.0.0"
                        )

                        SettingsRow(
                            icon: "hand.raised",
                            title: "Privacy Policy",
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
                locationService.requestAuthorization()
            } else {
                locationService.stopMonitoring()
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
