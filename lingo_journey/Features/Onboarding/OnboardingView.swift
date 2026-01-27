import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform",
            title: "Translate With Confidence",
            description: "Instantly understand and communicate in any language with ease."
        ),
        OnboardingPage(
            icon: "person.2",
            title: "Face-to-Face Conversations",
            description: "Have natural conversations with anyone, regardless of language barriers."
        ),
        OnboardingPage(
            icon: "arrow.down.circle",
            title: "Works Offline",
            description: "Download languages to translate anywhere, even without internet."
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: AppSpacing.md) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.appPrimary : Color.appTextMuted)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, AppSpacing.xxl)

                PrimaryButton(
                    title: currentPage == pages.count - 1 ? "Get Started" : "Next",
                    action: {
                        if currentPage == pages.count - 1 {
                            hasCompletedOnboarding = true
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                )
                .padding(.horizontal, AppSpacing.xxxl)
                .padding(.bottom, AppSpacing.page)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: AppSpacing.xxxl) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(.appPrimary)

            VStack(spacing: AppSpacing.xl) {
                Text(page.title)
                    .font(.appTitle1)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxxl)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
