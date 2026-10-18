import AppKit
import SwiftUI
import TabulaCore

/// Kaleidoscope-inspired colors. Every token resolves per appearance (aqua / darkAqua).
enum Palette {
    static let violet = dynamic(light: 0x9859F6, dark: 0xA57CF8)
    static let headerBackground = dynamic(light: 0xF8F3FE, dark: 0x342D41)
    static let headerRule = dynamic(light: hex(0x9859F6, alpha: 0.22), dark: hex(0xA57CF8, alpha: 0.35))
    static let hover = dynamic(light: hex(0x9859F6, alpha: 0.05), dark: hex(0xA57CF8, alpha: 0.10))
    static let selection = dynamic(light: hex(0x9859F6, alpha: 0.16), dark: hex(0xA57CF8, alpha: 0.30))
    static let selectionInactive = Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
    static let rowBase = Color(nsColor: NSColor.alternatingContentBackgroundColors[0])
    static let rowAlternate = Color(nsColor: NSColor.alternatingContentBackgroundColors[1])
    static let badgeFill = dynamic(light: 0xECE2FD, dark: 0x3B2D57)
    static let badgeInk = dynamic(light: 0x7A3FE4, dark: 0xCDB6FF)
    static let codeBackground = Color.primary.opacity(0.07)
    static let separator = Color(nsColor: .separatorColor)

    static func fill(_ tone: ValueTone) -> Color {
        switch tone {
        case .neutral: .clear
        case .positive: dynamic(light: 0xD7F0D7, dark: 0x1E3B24)
        case .negative: dynamic(light: 0xF6DCD8, dark: 0x4A2320)
        case .changed: dynamic(light: 0xE1ECFC, dark: 0x1D2D4B)
        case .warning: dynamic(light: 0xF7EBC2, dark: 0x3E3317)
        }
    }

    static func ink(_ tone: ValueTone) -> Color {
        switch tone {
        case .neutral: .primary
        case .positive: dynamic(light: 0x2A7432, dark: 0x7BD88A)
        case .negative: dynamic(light: 0xB3392F, dark: 0xFF8E80)
        case .changed: dynamic(light: 0x2D63C6, dark: 0x8DB7FF)
        case .warning: dynamic(light: 0x8A5F00, dark: 0xF2C94C)
        }
    }

    static func symbol(_ tone: ValueTone) -> String {
        switch tone {
        case .neutral: "circle.fill"
        case .positive: "checkmark"
        case .negative: "xmark"
        case .changed: "pencil"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    private static func dynamic(light: Int, dark: Int) -> Color {
        dynamic(light: hex(light), dark: hex(dark))
    }

    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }

    private static func hex(_ value: Int, alpha: CGFloat = 1) -> NSColor {
        NSColor(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: alpha
        )
    }
}

enum Metrics {
    static let headerHeight: CGFloat = 34
    static let rowMinHeight: CGFloat = 30
    static let cellHorizontalPadding: CGFloat = 12
    static let cellVerticalPadding: CGFloat = 7
    static let bodyFontSize: CGFloat = 13
}

extension ColumnAlignment {
    var frameAlignment: Alignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}
