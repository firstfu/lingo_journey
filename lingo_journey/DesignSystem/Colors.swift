import SwiftUI

// MARK: - App Colors
extension Color {
    // Background
    static let appBackground = Color(hex: "0A1628")
    static let appSurface = Color(hex: "0F2744")
    static let appSurfaceElevated = Color(hex: "162D4A")

    // Primary
    static let appPrimary = Color(hex: "4A9EFF")
    static let appPrimaryMuted = Color(hex: "2563EB")

    // Text
    static let appTextPrimary = Color.white
    static let appTextSecondary = Color(hex: "8E9BAE")
    static let appTextMuted = Color(hex: "5A6B7D")

    // Utility
    static let appBorder = Color(hex: "1E3A5F")
    static let appSuccess = Color(hex: "10B981")
    static let appWarning = Color(hex: "F59E0B")
    static let appError = Color(hex: "EF4444")
}

// MARK: - Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
