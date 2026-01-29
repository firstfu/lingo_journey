import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("terms.title")
                        .font(.appTitle1)
                        .foregroundColor(.appTextPrimary)

                    Text("terms.lastUpdated")
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }

                // Sections
                PolicySection(
                    title: String(localized: "terms.acceptance.title"),
                    content: String(localized: "terms.acceptance.content")
                )

                PolicySection(
                    title: String(localized: "terms.serviceDescription.title"),
                    content: String(localized: "terms.serviceDescription.content")
                )

                PolicySection(
                    title: String(localized: "terms.restrictions.title"),
                    content: String(localized: "terms.restrictions.content")
                )

                PolicySection(
                    title: String(localized: "terms.accuracy.title"),
                    content: String(localized: "terms.accuracy.content")
                )

                PolicySection(
                    title: String(localized: "terms.intellectualProperty.title"),
                    content: String(localized: "terms.intellectualProperty.content")
                )

                PolicySection(
                    title: String(localized: "terms.serviceChanges.title"),
                    content: String(localized: "terms.serviceChanges.content")
                )

                PolicySection(
                    title: String(localized: "terms.disclaimer.title"),
                    content: String(localized: "terms.disclaimer.content")
                )

                PolicySection(
                    title: String(localized: "terms.modifications.title"),
                    content: String(localized: "terms.modifications.content")
                )

                PolicySection(
                    title: String(localized: "terms.contact.title"),
                    content: String(localized: "terms.contact.content")
                )
            }
            .padding(AppSpacing.xl)
        }
        .background(Color.appBackground)
        .navigationTitle(Text("terms.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
