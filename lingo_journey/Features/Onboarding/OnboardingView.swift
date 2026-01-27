import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let titleKey: LocalizedStringKey
    let descriptionKey: LocalizedStringKey
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform",
            titleKey: "onboarding.title1",
            descriptionKey: "onboarding.description1"
        ),
        OnboardingPage(
            icon: "person.2",
            titleKey: "onboarding.title2",
            descriptionKey: "onboarding.description2"
        ),
        OnboardingPage(
            icon: "arrow.down.circle",
            titleKey: "onboarding.title3",
            descriptionKey: "onboarding.description3"
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
                    title: currentPage == pages.count - 1 ? String(localized: "onboarding.getStarted") : String(localized: "onboarding.next"),
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
                Text(page.titleKey)
                    .font(.appTitle1)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text(page.descriptionKey)
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
