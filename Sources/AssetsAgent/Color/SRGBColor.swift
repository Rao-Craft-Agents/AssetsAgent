//  WHAT: An sRGB colour as the catalog and the drawing share it: 8-bit channels (what a hex says and what a colour
//        set writes, `"0xA1"`) and an alpha. Read from hex, written to a colour set, drawn as a CGColor, measured for
//        contrast, and moved through OKLCH when a tone is derived.
//  PIN:  A HEX STAYS ITS HEX. A colour a call names is written into its colour set exactly; only derived tones
//        are rounded from OKLCH.

import CoreGraphics
import Foundation

struct SRGBColor: Hashable, Sendable, CustomStringConvertible {
    var red: Int
    var green: Int
    var blue: Int
    var alpha: Double

    init(red: Int, green: Int, blue: Int, alpha: Double = 1) {
        self.red = min(255, max(0, red)); self.green = min(255, max(0, green)); self.blue = min(255, max(0, blue))
        self.alpha = min(1, max(0, alpha))
    }

    /// `#RGB`, `#RRGGBB` or `#RRGGBBAA`, with `#`, `0x` or neither; nil for anything else.
    init?(hex text: String) {
        var digits = text.trimmingCharacters(in: .whitespaces)
        if digits.hasPrefix("#") { digits.removeFirst() } else if digits.lowercased().hasPrefix("0x") { digits.removeFirst(2) }
        guard [3, 6, 8].contains(digits.count), digits.allSatisfy(\.isHexDigit) else { return nil }
        if digits.count == 3 { digits = digits.map { "\($0)\($0)" }.joined() }
        let value = UInt64(digits, radix: 16)!
        if digits.count == 8 {
            self.init(red: Int(value >> 24 & 0xFF), green: Int(value >> 16 & 0xFF), blue: Int(value >> 8 & 0xFF), alpha: Double(value & 0xFF) / 255)
        } else {
            self.init(red: Int(value >> 16 & 0xFF), green: Int(value >> 8 & 0xFF), blue: Int(value & 0xFF))
        }
    }

    /// `0…1` channels, rounded to the nearest 8-bit step.
    init(r: Double, g: Double, b: Double, alpha: Double = 1) {
        self.init(red: Int((r * 255).rounded()), green: Int((g * 255).rounded()), blue: Int((b * 255).rounded()), alpha: alpha)
    }

    static let white = SRGBColor(red: 255, green: 255, blue: 255)
    static let black = SRGBColor(red: 0, green: 0, blue: 0)

    var r: Double { Double(red) / 255 }
    var g: Double { Double(green) / 255 }
    var b: Double { Double(blue) / 255 }

    /// `#RRGGBB`, and `AA` after it when the colour is not opaque.
    var hex: String {
        let base = String(format: "#%02X%02X%02X", red, green, blue)
        return alpha < 1 ? base + String(format: "%02X", Int((alpha * 255).rounded())) : base
    }

    var description: String { hex }

    var cgColor: CGColor {
        CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [r, g, b, alpha])!
    }

    func with(alpha: Double) -> SRGBColor { SRGBColor(red: red, green: green, blue: blue, alpha: alpha) }

    /// The colour's entry in a colour set: sRGB, its channels as Xcode's 8-bit hexadecimal input writes them.
    var catalogJSON: CatalogJSON {
        .object(["color-space": .string("srgb"), "components": .object([
            "alpha": .string(String(format: "%.3f", alpha)),
            "blue": .string(String(format: "0x%02X", blue)),
            "green": .string(String(format: "0x%02X", green)),
            "red": .string(String(format: "0x%02X", red)),
        ])])
    }

    // MARK: - Light

    /// WCAG relative luminance, 0 (black) to 1 (white).
    var luminance: Double {
        func linear(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// The WCAG contrast ratio with `other`, 1 to 21.
    func contrast(with other: SRGBColor) -> Double {
        let a = luminance, b = other.luminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Whether text in white reads better on it than text in black.
    var isDark: Bool { contrast(with: .white) >= contrast(with: .black) }

    var oklch: OKLCH { OKLCH(self) }

    /// `self` moved towards `other` by `amount` (0…1), in OKLab, so the middle does not go grey.
    func mixed(with other: SRGBColor, _ amount: Double) -> SRGBColor {
        let a = OKLCH.lab(self), b = OKLCH.lab(other)
        let t = min(1, max(0, amount))
        return OKLCH.rgb(lab: (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t, a.2 + (b.2 - a.2) * t), alpha: alpha + (other.alpha - alpha) * t)
    }

    /// The colour as grey of the same lightness.
    var grey: SRGBColor {
        let l = OKLCH(self).l
        return OKLCH(l: l, c: 0, h: 0).rgb
    }
}
