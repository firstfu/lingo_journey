import SwiftUI
import UIKit

enum PanelDetent {
    case collapsed
    case half
    case full

    var heightRatio: CGFloat {
        switch self {
        case .collapsed: return 0.15
        case .half: return 0.4
        case .full: return 0.85
        }
    }
}

struct DraggablePanel<Content: View>: View {
    @Binding var currentDetent: PanelDetent
    let content: () -> Content

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let maxHeight = geometry.size.height
            let currentHeight = maxHeight * currentDetent.heightRatio

            VStack(spacing: 0) {
                // Drag handle
                VStack(spacing: AppSpacing.md) {
                    Capsule()
                        .fill(Color.appTextMuted)
                        .frame(width: 36, height: 4)
                        .padding(.top, AppSpacing.md)

                    content()
                }
                .frame(maxWidth: .infinity)
                .frame(height: currentHeight + dragOffset, alignment: .top)
                .background(Color.appSurface)
                .clipShape(
                    RoundedCorner(radius: AppRadius.xl, corners: [.topLeft, .topRight])
                )
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = -value.translation.height
                        }
                        .onEnded { value in
                            let dragAmount = -value.translation.height
                            let velocity = -value.predictedEndTranslation.height

                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if velocity > 100 {
                                    // Swiping up
                                    switch currentDetent {
                                    case .collapsed: currentDetent = .half
                                    case .half: currentDetent = .full
                                    case .full: break
                                    }
                                } else if velocity < -100 {
                                    // Swiping down
                                    switch currentDetent {
                                    case .collapsed: break
                                    case .half: currentDetent = .collapsed
                                    case .full: currentDetent = .half
                                    }
                                } else {
                                    // Snap to nearest
                                    let newHeight = currentHeight + dragAmount
                                    let ratio = newHeight / maxHeight

                                    if ratio < 0.25 {
                                        currentDetent = .collapsed
                                    } else if ratio < 0.6 {
                                        currentDetent = .half
                                    } else {
                                        currentDetent = .full
                                    }
                                }
                            }
                        }
                )
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// Helper for rounded corners on specific corners
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        DraggablePanel(currentDetent: .constant(.half)) {
            VStack {
                Text("Panel Content")
                    .foregroundColor(.appTextPrimary)
            }
            .padding()
        }
    }
}
