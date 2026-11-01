//  WHAT: OKLCH, the perceptual lightness, chroma and hue a tone is derived in (Björn Ottosson's OKLab, polar):
//        a step of lightness looks like the same step at every hue, and a hue keeps its hue as it lightens.
//  PIN:  BACK INTO sRGB BY CHROMA, NEVER BY CLIPPING. A tone outside sRGB loses chroma until it fits, so its
//        lightness and hue stay what was asked for.

import Foundation

struct OKLCH: Equatable, Sendable {
    /// Lightness, 0 (black) to 1 (white).
    var l: Double
    /// Chroma, 0 (grey) to about 0.37.
    var c: Double
    /// Hue, in degrees.
    var h: Double

    init(l: Double, c: Double, h: Double) {
        self.l = l; self.c = max(0, c); self.h = (h.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    }

    init(_ color: SRGBColor) {
        let lab = Self.lab(color)
        let c = (lab.1 * lab.1 + lab.2 * lab.2).squareRoot()
        let h = c < 1e-5 ? 0 : atan2(lab.2, lab.1) * 180 / .pi
        self.init(l: lab.0, c: c, h: h)
    }

    /// The tone in sRGB, chroma reduced until it fits.
    var rgb: SRGBColor { rgb(alpha: 1) }

    func rgb(alpha: Double) -> SRGBColor {
        let lightness = min(1, max(0, l))
        var low = 0.0, high = c
        if Self.fits(lightness, high, h) { return Self.rgb(lab: Self.lab(lightness, high, h), alpha: alpha) }
        for _ in 0..<24 {
            let middle = (low + high) / 2
            if Self.fits(lightness, middle, h) { low = middle } else { high = middle }
        }
        return Self.rgb(lab: Self.lab(lightness, low, h), alpha: alpha)
    }

    /// This tone with its lightness, chroma or hue changed.
    func with(l: Double? = nil, c: Double? = nil, h: Double? = nil) -> OKLCH {
        OKLCH(l: l ?? self.l, c: c ?? self.c, h: h ?? self.h)
    }

    // MARK: - OKLab

    static func lab(_ l: Double, _ c: Double, _ h: Double) -> (Double, Double, Double) {
        let radians = h * .pi / 180
        return (l, c * cos(radians), c * sin(radians))
    }

    static func lab(_ color: SRGBColor) -> (Double, Double, Double) {
        func linear(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        let r = linear(color.r), g = linear(color.g), b = linear(color.b)
        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
                1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
                0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)
    }

    static func linearRGB(lab: (Double, Double, Double)) -> (Double, Double, Double) {
        let l = pow(lab.0 + 0.3963377774 * lab.1 + 0.2158037573 * lab.2, 3)
        let m = pow(lab.0 - 0.1055613458 * lab.1 - 0.0638541728 * lab.2, 3)
        let s = pow(lab.0 - 0.0894841775 * lab.1 - 1.2914855480 * lab.2, 3)
        return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
                -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
                -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)
    }

    static func rgb(lab: (Double, Double, Double), alpha: Double) -> SRGBColor {
        let linear = linearRGB(lab: lab)
        func gamma(_ c: Double) -> Double {
            let v = min(1, max(0, c))
            return v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1 / 2.4) - 0.055
        }
        return SRGBColor(r: gamma(linear.0), g: gamma(linear.1), b: gamma(linear.2), alpha: alpha)
    }

    private static func fits(_ l: Double, _ c: Double, _ h: Double) -> Bool {
        let linear = linearRGB(lab: lab(l, c, h))
        let slack = 0.0005
        return [linear.0, linear.1, linear.2].allSatisfy { $0 >= -slack && $0 <= 1 + slack }
    }
}
