//  WHAT: How a brand surface is painted, the same on an icon, a badge and a launch logo: a gradient a little off
//        vertical with a soft light from the top left (a single colour stays solid), and the mark on it with a
//        shadow tinted by the ground it falls on.

import CoreGraphics
import Foundation

enum Surface {
    /// Fills `rect` (clipped to `shape` when given) with `stops`, top to bottom, with a soft light of `sheen`.
    ///
    /// PIN: NO SHEEN IN A PDF. A gradient's alpha does not survive a PDF page (it draws opaque white), so vector
    /// surfaces pass 0 and keep the plain gradient.
    static func ground(_ stops: [SRGBColor], in rect: CGRect, shape: CGPath? = nil, sheen: Double = 0.14, context: CGContext) {
        context.saveGState()
        // Clipped to its own rect: a gradient extended past its ends would otherwise paint whatever draws the page.
        context.clip(to: rect)
        if let shape { context.addPath(shape); context.clip() }
        if stops.count == 1 {
            context.setFillColor(stops[0].cgColor)
            context.fill(rect)
        } else {
            let locations = stops.indices.map { CGFloat($0) / CGFloat(stops.count - 1) }
            let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: stops.map(\.cgColor) as CFArray, locations: locations)!
            context.drawLinearGradient(gradient, start: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY),
                                       end: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.minY), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            if sheen > 0 {
                let light = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                       colors: [SRGBColor.white.with(alpha: sheen).cgColor, SRGBColor.white.with(alpha: 0).cgColor] as CFArray, locations: [0, 1])!
                let origin = CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY + rect.height * 0.04)
                context.drawRadialGradient(light, startCenter: origin, startRadius: 0, endCenter: origin, endRadius: rect.width * 0.9, options: [])
            }
        }
        context.restoreGState()
    }

    /// Paints `art` in `frame` in `ink`, with a soft shadow of `shadow` when given (bitmaps only: a PDF stays flat).
    static func mark(_ art: MarkArt, in frame: CGRect, ink: SRGBColor, shadow: SRGBColor?, scale: CGFloat = 1, context: CGContext) {
        let box = art.box(in: frame, scale: scale)
        context.saveGState()
        if let shadow {
            let side = min(frame.width, frame.height)
            context.setShadow(offset: CGSize(width: 0, height: -side * 0.012), blur: side * 0.032, color: shadow.cgColor)
            context.beginTransparencyLayer(auxiliaryInfo: nil)
            art.paint(in: box, ink: ink, context: context)
            context.endTransparencyLayer()
        } else {
            art.paint(in: box, ink: ink, context: context)
        }
        context.restoreGState()
    }

    /// The shadow a mark in `ink` casts on `ground`: the ground's own darkest tone, deeper, not grey.
    static func shadow(for ink: SRGBColor, on ground: [SRGBColor]) -> SRGBColor {
        let darkest = ground.min { $0.luminance < $1.luminance } ?? .black
        let tone = darkest.oklch
        let deep = OKLCH(l: min(tone.l * 0.45, 0.2), c: tone.c * 0.8, h: tone.h).rgb
        return deep.with(alpha: ink.isDark ? 0.16 : 0.34)
    }
}
