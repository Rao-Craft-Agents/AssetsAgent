//  WHAT: Placeholder avatars as vector PDFs, square so a view may clip them to any shape: the neutral one (a head
//        and shoulders on a soft ground of the brand's tint, light and dark) and sample avatars for previews and
//        seed data (two initials on a gradient of a hue beside the brand's).

import CoreGraphics
import Foundation

struct AvatarPainter {
    let brand: Brand

    /// The initials and hue turns (from the brand's hue) of the sample avatars.
    static let samples: [(initials: String, turn: Double)] = [("AK", -38), ("JM", 32), ("RS", 150), ("TL", 212)]

    /// `hue` moved out of the yellows (50°–115° in OKLCH), which turn olive and mustard as dark as white initials
    /// need: towards orange below the middle of that band, towards green above it.
    static func clearHue(_ hue: Double) -> Double {
        let h = (hue.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        guard (50...115).contains(h) else { return h }
        return h < 82 ? 42 : 150
    }

    /// The neutral avatar, `side` points square.
    func neutral(dark: Bool, side: CGFloat) -> Data {
        let tones = brand.tones
        let top = dark ? tones.neutral(0.36) : tones.neutral(0.93), bottom = dark ? tones.neutral(0.29) : tones.neutral(0.86)
        let figure = dark ? tones.neutral(0.52) : tones.neutral(0.74)
        return VectorPage.pdf(width: side, height: side) { context in
            let rect = CGRect(x: 0, y: 0, width: side, height: side)
            Surface.ground([top, bottom], in: rect, sheen: 0, context: context)
            context.setFillColor(figure.cgColor)
            context.addPath(Glyphs.circle(CGPoint(x: side * 0.5, y: side * 0.605), side * 0.185))
            context.fillPath()
            let shoulders = CGPath(ellipseIn: CGRect(x: side * 0.16, y: -side * 0.3, width: side * 0.68, height: side * 0.66), transform: nil)
            context.clip(to: rect)
            context.addPath(shoulders)
            context.fillPath()
        }
    }

    /// Sample avatar `index` (0…3), `side` points square: its initials in white on its gradient.
    func sample(_ index: Int, side: CGFloat) throws -> Data {
        let sample = Self.samples[index % Self.samples.count]
        let hue = Self.clearHue(brand.tones.vivid.oklch.h + sample.turn)
        let top = OKLCH(l: 0.74, c: 0.13, h: hue - 12).rgb, bottom = OKLCH(l: 0.56, c: 0.15, h: hue + 10).rgb
        let face = brand.fonts.wordmark
        let size = side * 0.36 / max(TextOutline.capHeight(font: face, size: 1), 0.01)
        let letters = try TextOutline.path(sample.initials, font: face, size: size, tracking: 0.02)
        let ink = letters.boundingBoxOfPath
        return VectorPage.pdf(width: side, height: side) { context in
            Surface.ground([top, bottom], in: CGRect(x: 0, y: 0, width: side, height: side), sheen: 0, context: context)
            context.translateBy(x: side / 2 - ink.midX, y: side / 2 - ink.midY)
            context.addPath(letters)
            context.setFillColor(SRGBColor.white.cgColor)
            context.fillPath()
        }
    }
}
