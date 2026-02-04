import SwiftUI
import UIKit

struct ScanResultCard: View {
    let result: ScanResult
    let isSelected: Bool
    let onTap: () -> Void
    let onCopy: () -> Void

    @State private var showCopied = false

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(result.originalText)
                        .font(.appSubheadline)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)

                    if result.isTranslating {
                        HStack(spacing: AppSpacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                                .scaleEffect(0.7)
                            Text("翻譯中...")
                                .font(.appBody)
                                .foregroundColor(.appTextMuted)
                        }
                    } else if let translated = result.translatedText {
                        Text(translated)
                            .font(.appBody)
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: handleCopy) {
                    ZStack {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(showCopied ? .appSuccess : .appTextSecondary)
                    }
                    .frame(width: 44, height: 44)
                }
                .disabled(result.translatedText == nil)
            }
            .padding(AppSpacing.xl)
            .background(isSelected ? Color.appPrimary.opacity(0.15) : Color.appSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func handleCopy() {
        guard let text = result.translatedText else { return }
        UIPasteboard.general.string = text

        withAnimation(.easeOut(duration: 0.15)) {
            showCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showCopied = false
            }
        }

        onCopy()
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppSpacing.lg) {
            ScanResultCard(
                result: ScanResult(
                    originalText: "Menu du jour",
                    translatedText: "今日菜單",
                    boundingBox: .zero,
                    translationFailed: false
                ),
                isSelected: false,
                onTap: {},
                onCopy: {}
            )

            ScanResultCard(
                result: ScanResult(
                    originalText: "Soupe à l'oignon",
                    boundingBox: .zero,
                    isTranslating: true,
                    translationFailed: false
                ),
                isSelected: true,
                onTap: {},
                onCopy: {}
            )
        }
        .padding()
    }
}
