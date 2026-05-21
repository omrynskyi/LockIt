import SwiftUI

enum Theme {
    // MARK: - Colors (exact from Figma)
    static let gradientStart  = Color(hex: "FFEAB5")   // 0%   warm cream
    static let gradientMid    = Color(hex: "FAFAFA")   // 32%  near-white
    static let gradientEnd    = Color(hex: "B4CFFF")   // 100% soft periwinkle

    static let cardBackground = Color.white.opacity(0.68)
    static let textPrimary    = Color(red: 0.17, green: 0.17, blue: 0.24)
    static let textSecondary  = Color(red: 0.52, green: 0.53, blue: 0.62)
    static let fieldLine      = Color(red: 0.72, green: 0.75, blue: 0.84)

    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        stops: [
            .init(color: gradientStart, location: 0.00),
            .init(color: gradientMid,   location: 0.32),
            .init(color: gradientEnd,   location: 1.00)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let buttonGradient = LinearGradient(
        colors: [Color(hex: "4B75FF"), Color(hex: "8EA8FF")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Fonts (both registered at launch in LockitApp)

    /// Imperial Script — used for all main headings/titles
    static func script(_ size: CGFloat) -> Font {
        .custom("ImperialScript-Regular", size: size)
    }

    /// Cormorant Garamond — used for body, labels, buttons, fields
    static func serif(_ size: CGFloat, italic: Bool = false, bold: Bool = false) -> Font {
        let name: String
        switch (italic, bold) {
        case (true,  false): name = "CormorantGaramond-LightItalic"
        case (true,  true):  name = "CormorantGaramond-Italic"
        case (false, true):  name = "CormorantGaramond-Bold"
        default:             name = "CormorantGaramond-Regular"
        }
        return .custom(name, size: size)
    }

    static let appLabel   = serif(13)
    static let bodyText   = Font.system(size: 16, weight: .regular)
    static let caption    = Font.system(size: 14, weight: .light)
    static let fieldLabel = Font.system(size: 15, weight: .light)
}

// MARK: - Hex color convenience
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
