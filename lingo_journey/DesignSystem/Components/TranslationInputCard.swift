import SwiftUI

struct TranslationInputCard: View {
    let languageName: String
    @Binding var text: String
    var onCameraTap: (() -> Void)?
    var onMicTap: () -> Void
    var isListening: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(languageName)
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                HStack(spacing: AppSpacing.md) {
                    // Camera button
                    if let onCameraTap = onCameraTap {
                        Button(action: onCameraTap) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 20))
                                .foregroundColor(.appTextSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }

                    // Mic button
                    Button(action: onMicTap) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 20))
                            .foregroundColor(isListening ? .appPrimary : .appTextSecondary)
                            .frame(width: 44, height: 44)
                            .background(isListening ? Color.appPrimary.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }

            TextField("Enter your text here...", text: $text, axis: .vertical)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .lineLimit(5...10)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        TranslationInputCard(
            languageName: "English",
            text: .constant("Hello, how are you?"),
            onCameraTap: {},
            onMicTap: {},
            isListening: false
        )
        .padding()
    }
}
