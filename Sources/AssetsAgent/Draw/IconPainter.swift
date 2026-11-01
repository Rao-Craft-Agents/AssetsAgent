//  WHAT: The app icon in every form a platform asks for: iOS's 1024 square in its light, dark and tinted looks,
//        macOS's rounded square at ten sizes on Apple's grid, watchOS's square, and visionOS's three layers.
//  PIN:  EVERY SIZE IS DRAWN, NEVER SCALED DOWN. A 16-pixel icon is drawn at 16 pixels from the mark's small cut,
//        so it stays sharp and legible instead of a blur of the 1024 one.
//  PIN:  APPLE'S macOS GRID. The shape is 824 of 1024 with 100 to spare all round, its corners continuous at a
//        radius of 185.4, a shadow 12 below it blurred by 24; nothing else is drawn in the margin.
//  PIN:  iOS ICONS ARE OPAQUE SQUARES. The system rounds them; an alpha channel is refused by the App Store.

import CoreGraphics
import Foundation

struct IconPainter {
    let brand: Brand
    let art: MarkArt
    let smallArt: MarkArt
    let tinyArt: MarkArt

    enum Look { case light, dark, tinted }

    init(brand: Brand) throws {
        self.brand = brand
        art = try MarkArt.make(brand)
        smallArt = try MarkArt.make(brand, size: .small)
        tinyArt = try MarkArt.make(brand, size: .tiny)
    }

    private var tones: BrandTones { brand.tones }

    /// An iOS icon: 1024 pixels, opaque, full bleed.
    func ios(_ look: Look) -> Data {
        Raster.png(square(1024, look: look, markScale: 1))
    }

    /// The watchOS icon: the light look, the mark a little smaller for the round crop.
    func watch() -> Data {
        Raster.png(square(1024, look: .light, markScale: 0.92))
    }

    private func square(_ side: Int, look: Look, markScale: CGFloat) -> CGImage {
        let frame = CGRect(x: 0, y: 0, width: side, height: side)
        let image = Raster.image(width: side, height: side, opaque: true) { context in
            if art.isWholeIcon {
                if look == .dark { Surface.ground(tones.darkBackground, in: frame, sheen: 0, context: context) }
                art.paint(in: frame, ink: tones.mark, context: context)
                if look == .dark {
                    context.setFillColor(SRGBColor.black.with(alpha: 0.35).cgColor)
                    context.fill(frame)
                }
                return
            }
            switch look {
            case .light:
                Surface.ground(tones.background, in: frame, context: context)
                Surface.mark(art, in: frame, ink: tones.mark, shadow: Surface.shadow(for: tones.mark, on: tones.background), scale: markScale, context: context)
            case .dark:
                Surface.ground(tones.darkBackground, in: frame, sheen: 0.05, context: context)
                Surface.mark(art, in: frame, ink: tones.darkMark, shadow: SRGBColor.black.with(alpha: 0.4), scale: markScale, context: context)
            case .tinted:
                context.setFillColor(SRGBColor.black.cgColor)
                context.fill(frame)
                Surface.mark(art, in: frame, ink: .white, shadow: nil, scale: markScale, context: context)
            }
        }
        return look == .tinted ? Raster.desaturated(image, opaque: true) : image
    }

    /// A macOS icon `pixels` wide: the rounded square on Apple's grid, with its shadow, on a clear canvas.
    func mac(pixels: Int) -> Data {
        let scale = CGFloat(pixels) / 1024
        let small = pixels <= 32
        var body = CGRect(x: 100 * scale, y: 100 * scale, width: 824 * scale, height: 824 * scale)
        if pixels <= 64 { body = body.integral.insetBy(dx: 0, dy: 0) }
        let image = Raster.image(width: pixels, height: pixels, opaque: false) { context in
            let shape = Squircle.path(body, radius: 185.4 * scale)
            context.saveGState()
            context.setShadow(offset: CGSize(width: 0, height: -12 * scale), blur: 24 * scale, color: SRGBColor.black.with(alpha: 0.3).cgColor)
            context.beginTransparencyLayer(auxiliaryInfo: nil)
            if art.isWholeIcon {
                context.addPath(shape); context.clip()
                art.paint(in: body, ink: tones.mark, context: context)
            } else {
                Surface.ground(tones.background, in: body, shape: shape, context: context)
            }
            context.endTransparencyLayer()
            context.restoreGState()
            guard !art.isWholeIcon else { return }
            let mark = pixels <= 16 ? tinyArt : small ? smallArt : art
            Surface.mark(mark, in: body, ink: tones.mark, shadow: small ? nil : Surface.shadow(for: tones.mark, on: tones.background), context: context)
        }
        return Raster.png(image)
    }

    /// The visionOS icon's layers, front to back: the mark, a soft light, the ground. visionOS crops them round and
    /// gives them depth, so the mark sits a little smaller and casts no shadow of its own.
    func vision() -> [Data] {
        let side = 1024, frame = CGRect(x: 0, y: 0, width: side, height: side)
        let front = Raster.image(width: side, height: side, opaque: false) { context in
            guard !art.isWholeIcon else { return }
            // visionOS lights and shadows its layers itself: nothing is baked into them.
            Surface.mark(art, in: frame, ink: tones.mark, shadow: nil, scale: 0.9, context: context)
        }
        let middle = Raster.image(width: side, height: side, opaque: false) { context in
            let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  colors: [SRGBColor.white.with(alpha: 0.2).cgColor, SRGBColor.white.with(alpha: 0).cgColor] as CFArray, locations: [0, 1])!
            let center = CGPoint(x: frame.midX, y: frame.midY)
            context.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: CGFloat(side) * 0.38, options: [])
        }
        let back = Raster.image(width: side, height: side, opaque: true) { context in
            if art.isWholeIcon { art.paint(in: frame, ink: tones.mark, context: context) } else { Surface.ground(tones.background, in: frame, context: context) }
        }
        return [Raster.png(front), Raster.png(middle), Raster.png(back)]
    }
}
