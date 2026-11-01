//  WHAT: The brand's logos as vector PDFs: the badge (the mark on the brand's ground in a circle, as `Logo`, or in
//        the icon's rounded square, as `LaunchLogo`), the mark alone in one ink (`LogoMark`, a template), the name
//        set in the brand's face and outlined (`Wordmark`), and the badge beside the name (`Lockup`).
//  PIN:  THE DARK LOGO IS THE DARK ICON. In dark appearance a badge takes the dark icon's ground and mark, with a
//        faint rim so it still parts from a dark page; the wordmark turns to the brand's light ink.
//  PIN:  TEXT IS OUTLINED. A logo carries the shapes of its letters, never a font.

import CoreGraphics
import Foundation

struct LogoPainter {
    let brand: Brand
    let art: MarkArt

    enum Look { case light, dark }
    enum Outline { case circle, squircle }

    init(brand: Brand) throws {
        self.brand = brand
        art = try MarkArt.make(brand)
    }

    private var tones: BrandTones { brand.tones }

    /// The badge, `side` points square.
    func badge(_ look: Look, outline: Outline, side: CGFloat) -> Data {
        VectorPage.pdf(width: side, height: side) { context in
            drawBadge(look, outline: outline, in: CGRect(x: 0, y: 0, width: side, height: side), context: context)
        }
    }

    private func drawBadge(_ look: Look, outline: Outline, in rect: CGRect, context: CGContext) {
        let shape = outline == .circle ? CGPath(ellipseIn: rect, transform: nil) : Squircle.path(rect, radius: rect.width * 0.225)
        if art.isWholeIcon {
            context.saveGState()
            context.addPath(shape); context.clip()
            art.paint(in: rect, ink: tones.mark, context: context)
            context.restoreGState()
            return
        }
        let dark = look == .dark
        Surface.ground(dark ? tones.darkBackground : tones.background, in: rect, shape: shape, sheen: 0, context: context)
        // A circle crops the corners an icon's square leaves: the mark sits a little smaller in it.
        Surface.mark(art, in: rect, ink: dark ? tones.darkMark : tones.mark, shadow: nil, scale: outline == .circle ? 0.94 : 1, context: context)
        if dark {
            context.saveGState()
            context.addPath(shape); context.clip()
            context.addPath(shape)
            context.setStrokeColor(SRGBColor.white.with(alpha: 0.14).cgColor)
            context.setLineWidth(rect.width * 0.02)
            context.strokePath()
            context.restoreGState()
        }
    }

    /// The mark alone in black, cropped to its ink, its longer side `side` points: drawn as a template.
    func mark(side: CGFloat) -> Data {
        let bounds = art.bounds
        let scale = side / max(bounds.width, bounds.height)
        let width = (bounds.width * scale).rounded(.up), height = (bounds.height * scale).rounded(.up)
        return VectorPage.pdf(width: width, height: height) { context in
            let box = CGRect(x: -bounds.minX * scale + (width - bounds.width * scale) / 2,
                             y: -bounds.minY * scale + (height - bounds.height * scale) / 2, width: scale, height: scale)
            if let picture = art.picture {
                picture.draw(in: CGRect(x: 0, y: 0, width: width, height: height), context: context)
            } else {
                art.paint(in: box, ink: .black, context: context)
            }
        }
    }

    /// The name, outlined in the wordmark's face: its capitals `capHeight` points tall.
    func wordmark(_ look: Look, capHeight: CGFloat) throws -> Data {
        let (path, size) = try wordmarkPath(capHeight: capHeight)
        let ink = path.boundingBoxOfPath
        let pad = (size * 0.06).rounded(.up)
        return VectorPage.pdf(width: (ink.width + pad * 2).rounded(.up), height: (ink.height + pad * 2).rounded(.up)) { context in
            context.translateBy(x: pad - ink.minX, y: pad - ink.minY)
            context.addPath(path)
            context.setFillColor((look == .dark ? tones.darkInk : tones.ink).cgColor)
            context.fillPath()
        }
    }

    /// The circle badge, `height` points, and the name beside it, centred on it.
    func lockup(_ look: Look, height: CGFloat) throws -> Data {
        let (path, _) = try wordmarkPath(capHeight: height * 0.4)
        let ink = path.boundingBoxOfPath
        let gap = height * 0.3, pad = (height * 0.04).rounded(.up)
        let capHeight = height * 0.4
        let baseline = height / 2 - capHeight / 2
        let textBottom = baseline + ink.minY, textTop = baseline + ink.maxY
        let bottom = min(0, textBottom), top = max(height, textTop)
        let width = height + gap + ink.maxX + pad * 2, pageHeight = top - bottom + pad * 2
        return VectorPage.pdf(width: width.rounded(.up), height: pageHeight.rounded(.up)) { context in
            context.translateBy(x: pad, y: pad - bottom)
            drawBadge(look, outline: .circle, in: CGRect(x: 0, y: 0, width: height, height: height), context: context)
            context.translateBy(x: height + gap, y: baseline)
            context.addPath(path)
            context.setFillColor((look == .dark ? tones.darkInk : tones.ink).cgColor)
            context.fillPath()
        }
    }

    /// The wordmark's outline with its capitals `capHeight` tall, baseline at 0, and the size it was set at.
    private func wordmarkPath(capHeight: CGFloat) throws -> (CGPath, CGFloat) {
        let face = brand.fonts.wordmark
        let unit = TextOutline.capHeight(font: face, size: 100)
        let size = capHeight / max(unit, 1) * 100
        return (try TextOutline.path(brand.wordmark, font: face, size: size, tracking: 0.015), size)
    }
}
