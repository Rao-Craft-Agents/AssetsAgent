//  WHAT: The brand's mark ready to draw: its outlines fitted to a unit box (or its picture), the share of a frame it
//        takes, and how it is painted in one ink.
//  PIN:  OPTICAL SIZE, NOT BOX SIZE. A single letter, two letters, a ring and a square grid fill their boxes
//        differently; each takes the share of the frame that makes them all look the same size on an icon, and a
//        narrow letter stands taller than a round one.

import CoreGraphics
import Foundation

struct MarkArt {
    /// The outlines, fitted to the unit box and centred in it by their ink.
    var layers: [MarkLayer]
    /// The picture, when the mark is one.
    var picture: Picture?
    /// The share of a frame's side the unit box takes.
    var share: CGFloat
    /// The outlines' bounds in the unit box (all of it for a picture).
    var bounds: CGRect

    static func make(_ brand: Brand, size: MarkSize = .regular) throws -> MarkArt {
        var art: MarkArt
        let small = size != .regular
        switch brand.mark {
        case .monogram(let word):
            // Two or three letters cannot be told apart at 16 pixels: the tiny cut keeps the first.
            let letters = size == .tiny ? String(word.prefix(1)) : word
            let outline = try TextOutline.path(letters, font: brand.fonts.monogram, size: 100, tracking: letters.count > 1 ? 0.01 : 0)
            var share: CGFloat = letters.count == 1 ? 0.5 : letters.count == 2 ? 0.6 : 0.66
            // A narrow letter (l, I, ℓ) set at a wide one's height looks small: it stands up to a sixth taller.
            let ink = outline.boundingBoxOfPath
            let aspect = ink.width / max(ink.height, 1)
            share *= 1 + 0.16 * min(1, max(0, (0.7 - aspect) / 0.4))
            art = fitted([MarkLayer(path: outline, opacity: 1)], share: share)
        case .shape(let shape):
            let shares: [AssetsShape: CGFloat] = [.ring: 0.56, .knot: 0.6, .wave: 0.56, .spark: 0.58, .stack: 0.56, .leaf: 0.62, .bubble: 0.56, .grid: 0.5]
            art = fitted(Glyphs.layers(shape, small: small), share: shares[shape] ?? 0.56)
        case .image(let picture):
            let aspect = picture.size.width / max(picture.size.height, 1)
            let bounds = aspect >= 1 ? CGRect(x: 0, y: (1 - 1 / aspect) / 2, width: 1, height: 1 / aspect)
                                     : CGRect(x: (1 - aspect) / 2, y: 0, width: aspect, height: 1)
            art = MarkArt(layers: [], picture: picture, share: picture.isFullBleed ? 1 : 0.62, bounds: bounds)
        }
        if art.picture?.isFullBleed != true {
            if size == .small { art.share = min(art.share * 1.14, 0.74) }
            if size == .tiny { art.share = min(art.share * 1.24, 0.78) }
        }
        return art
    }

    /// `layers` scaled to fit the unit box and centred in it by their ink.
    static func fitted(_ layers: [MarkLayer], share: CGFloat) -> MarkArt {
        let ink = layers.map(\.path.boundingBoxOfPath).reduce(CGRect.null) { $0.union($1) }
        guard !ink.isNull, ink.width > 0, ink.height > 0 else { return MarkArt(layers: layers, picture: nil, share: share, bounds: .init(x: 0, y: 0, width: 1, height: 1)) }
        let scale = 1 / max(ink.width, ink.height)
        var transform = CGAffineTransform(translationX: 0.5, y: 0.5).scaledBy(x: scale, y: scale).translatedBy(x: -ink.midX, y: -ink.midY)
        let moved = layers.map { MarkLayer(path: $0.path.copy(using: &transform) ?? $0.path, opacity: $0.opacity) }
        let bounds = CGRect(x: 0.5 - ink.width * scale / 2, y: 0.5 - ink.height * scale / 2, width: ink.width * scale, height: ink.height * scale)
        return MarkArt(layers: moved, picture: nil, share: share, bounds: bounds)
    }

    /// Whether the mark is a whole icon in itself (a full-bleed picture) rather than something set on a ground.
    var isWholeIcon: Bool { picture?.isFullBleed == true }

    /// The square the unit box is drawn in: centred in `frame`, its side the frame's at the mark's share.
    func box(in frame: CGRect, scale: CGFloat = 1) -> CGRect {
        let side = min(frame.width, frame.height) * share * scale
        return CGRect(x: frame.midX - side / 2, y: frame.midY - side / 2, width: side, height: side)
    }

    /// Paints the mark with its unit box on `box`: outlines in `ink` at each layer's opacity, a picture as it is.
    func paint(in box: CGRect, ink: SRGBColor, context: CGContext) {
        if let picture {
            picture.draw(in: box, context: context)
            return
        }
        var transform = CGAffineTransform(translationX: box.minX, y: box.minY).scaledBy(x: box.width, y: box.height)
        for layer in layers {
            guard let path = layer.path.copy(using: &transform) else { continue }
            context.addPath(path)
            context.setFillColor(ink.with(alpha: ink.alpha * Double(layer.opacity)).cgColor)
            context.fillPath()
        }
    }
}
