import SwiftUI

/// 首次翻譯引導提示
/// 當語言包尚未下載時，在系統彈窗出現前顯示此提示，讓用戶了解接下來會發生什麼
struct TranslationGuideSheet: View {
    @Binding var isPresented: Bool
    @Binding var dontShowAgain: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xxl) {
            // Icon
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundColor(.appPrimary)
                .padding(.top, AppSpacing.xxl)

            // Title
            Text(String(localized: "translation.guide.title"))
                .font(.appTitle2)
                .foregroundColor(.appTextPrimary)

            // Description
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(String(localized: "translation.guide.description"))
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    guideRow(
                        icon: "arrow.down.circle",
                        text: String(localized: "translation.guide.option.download")
                    )
                    guideRow(
                        icon: "checkmark.circle",
                        text: String(localized: "translation.guide.option.skip")
                    )
                }
                .padding(.top, AppSpacing.md)
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            // Continue button
            PrimaryButton(
                title: String(localized: "translation.guide.continue"),
                action: {
                    isPresented = false
                    onContinue()
                }
            )
            .padding(.horizontal, AppSpacing.xl)

            // Don't show again checkbox
            Button {
                dontShowAgain.toggle()
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                        .foregroundColor(dontShowAgain ? .appPrimary : .appTextSecondary)
                    Text(String(localized: "translation.guide.dontShowAgain"))
                        .font(.appCaption)
                        .foregroundColor(.appTextSecondary)
                }
            }
            .padding(.bottom, AppSpacing.xxl)
        }
        .background(Color.appSurface)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func guideRow(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .foregroundColor(.appPrimary)
                .frame(width: 24)
            Text(text)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
        }
    }
}

#Preview {
    Color.appBackground
        .sheet(isPresented: .constant(true)) {
            TranslationGuideSheet(
                isPresented: .constant(true),
                dontShowAgain: .constant(false),
                onContinue: {}
            )
        }
}
