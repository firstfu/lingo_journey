import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(.appHeadline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isDisabled ? Color.appPrimaryMuted : Color.appPrimary)
            .clipShape(Capsule())
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Get Started", action: {})
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
    .background(Color.appBackground)
}
