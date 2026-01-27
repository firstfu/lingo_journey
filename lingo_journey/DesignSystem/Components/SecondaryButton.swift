import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appHeadline)
                .foregroundColor(isDisabled ? .appTextMuted : .appPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.appSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isDisabled ? Color.appBorder : Color.appPrimary, lineWidth: 1)
                )
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        SecondaryButton(title: "Cancel", action: {})
        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
    .background(Color.appBackground)
}
