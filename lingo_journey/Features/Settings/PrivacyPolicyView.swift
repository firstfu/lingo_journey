import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("privacy.title")
                        .font(.appTitle1)
                        .foregroundColor(.appTextPrimary)

                    Text("privacy.lastUpdated")
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }

                // Sections
                PolicySection(
                    title: String(localized: "privacy.introduction.title"),
                    content: String(localized: "privacy.introduction.content")
                )

                PolicySection(
                    title: String(localized: "privacy.dataCollection.title"),
                    content: String(localized: "privacy.dataCollection.content")
                )

                PolicySection(
                    title: String(localized: "privacy.deviceData.title"),
                    content: String(localized: "privacy.deviceData.content")
                )

                PolicySection(
                    title: String(localized: "privacy.permissions.title"),
                    content: String(localized: "privacy.permissions.content")
                )

                PolicySection(
                    title: String(localized: "privacy.thirdParty.title"),
                    content: String(localized: "privacy.thirdParty.content")
                )

                PolicySection(
                    title: String(localized: "privacy.dataDeletion.title"),
                    content: String(localized: "privacy.dataDeletion.content")
                )

                PolicySection(
                    title: String(localized: "privacy.contact.title"),
                    content: String(localized: "privacy.contact.content")
                )
            }
            .padding(AppSpacing.xl)
        }
        .background(Color.appBackground)
        .navigationTitle(Text("privacy.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)

            Text(content)
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
