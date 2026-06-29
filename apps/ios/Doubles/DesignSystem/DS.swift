//
//  DS.swift
//  Doubles — the single source of truth for the design system.
//
//  Every view references these tokens. No hard-coded hex or font names in views.
//  Aesthetic: a primetime trash-TV title card. Glossy, dark, dramatic, screenshot-built.
//

import SwiftUI

// MARK: - Color(hex:)

extension Color {
    /// Build a colour from a 0xRRGGBB literal.
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Design tokens

enum DS {
    // Background & surfaces
    static let wine = Color(hex: 0x1B0B12)        // app background
    static let plum = Color(hex: 0x2A0E1F)        // gradient partner
    static let ink = Color(hex: 0x120208)         // text on bright accents
    static let surface = Color(hex: 0x22101A)     // cards
    static let surfaceLift = Color(hex: 0x2B1322) // raised cards, sheets

    // Text
    static let bone = Color(hex: 0xF6EFE7)        // primary text
    static let boneDim = Color(hex: 0xC9B6AE)     // secondary text

    // Accents
    static let magenta = Color(hex: 0xFF2E74)     // primary accent · "down"/danger
    static let acid = Color(hex: 0xE8FF59)        // secondary accent · "up"/success
    static let rose = Color(hex: 0xC98BA3)        // tertiary · quiet borders/labels

    static let line = Color(hex: 0xF6EFE7, alpha: 0.14) // hairline borders

    /// One assigned per double, for their avatar and identity.
    static let characters: [Color] = [
        0xFF2E74, 0xE8FF59, 0x7AD7FF, 0xFFB347, 0x9D8CFF, 0xC98BA3, 0x6FE0B0, 0xFF6B6B,
    ].map { Color(hex: $0) }

    /// Stable character colour for an id.
    static func characterColor(for id: String) -> Color {
        let hash = id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return characters[hash % characters.count]
    }

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 2   // sharp by default — the poster aesthetic
        static let chip: CGFloat = 999 // pills only
    }

    enum Dur {
        static let quick: Double = 0.15
        static let base: Double = 0.3
        static let dramatic: Double = 0.5
    }
}

// MARK: - Fonts
//
// Roles (brief §2):
//   display — Anton, uppercase impact (episode titles, headlines, awards, big numbers)
//   ui      — Bricolage Grotesque (beat text, labels, buttons, most UI)
//   mono    — Space Mono, letter-spaced (handles, timestamps, "EP 01", stats, chyron)
//
// PostScript names are verified against the bundled files. Bricolage ships as four
// instanced static weights so weight is honoured, not synthesised.

extension Font {
    /// Anton. Decorative impact type — fixed size (effectively caps under Dynamic Type).
    static func display(_ size: CGFloat) -> Font {
        .custom("Anton-Regular", fixedSize: size)
    }

    /// Anton that still scales with Dynamic Type, for accessibility-critical headings.
    static func displayScaling(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom("Anton-Regular", size: size, relativeTo: style)
    }

    static func ui(_ size: CGFloat, _ weight: Font.Weight = .medium, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(bricolage(for: weight), size: size, relativeTo: style)
    }

    static func mono(_ size: CGFloat, bold: Bool = false, relativeTo style: Font.TextStyle = .caption) -> Font {
        .custom(bold ? "SpaceMono-Bold" : "SpaceMono-Regular", size: size, relativeTo: style)
    }

    private static func bricolage(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light, .regular: return "BricolageGrotesque-Regular"
        case .medium: return "BricolageGrotesque-Medium"
        case .semibold: return "BricolageGrotesque-SemiBold"
        case .bold, .heavy, .black: return "BricolageGrotesque-ExtraBold"
        default: return "BricolageGrotesque-Medium"
        }
    }
}

// MARK: - Mono text helper (letter-spaced, uppercase)

extension View {
    /// Standard treatment for mono utility text: uppercase + tracking.
    func monoLabel(_ size: CGFloat = 11, bold: Bool = false, tracking: CGFloat = 1.5) -> some View {
        self.font(.mono(size, bold: bold))
            .tracking(tracking)
            .textCase(.uppercase)
    }
}
