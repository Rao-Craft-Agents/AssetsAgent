//  WHAT: A picture a call's `image` names (PNG, JPEG, HEIC, TIFF, PDF or SVG), kept as its bytes and drawn into any
//        context aspect-fit: a PDF as vectors, an SVG through AppKit, a bitmap as itself.
//  PIN:  A SQUARE, OPAQUE BITMAP IS A WHOLE ICON. It fills the canvas edge to edge instead of being set on the
//        brand's background as a mark.

import AppKit
import CoreGraphics
import Foundation
import ImageIO

struct Picture: Sendable, Equatable {
    enum Kind: Sendable, Equatable { case bitmap, pdf, svg }

    var data: Data
    var kind: Kind
    /// Its own size: pixels for a bitmap, points for a PDF or an SVG.
    var size: CGSize
    /// A square, opaque bitmap: a finished icon, drawn edge to edge.
    var isFullBleed: Bool

    static func load(_ url: URL) throws -> Picture {
        guard let data = try? Data(contentsOf: url) else { throw LineRefusal("image `\(url.path)` cannot be read") }
        let head = String(decoding: data.prefix(512), as: UTF8.self).lowercased()
        if url.pathExtension.lowercased() == "svg" || head.contains("<svg") {
            guard let image = NSImage(data: data), image.size.width > 0, image.size.height > 0 else {
                throw LineRefusal("image `\(url.lastPathComponent)` is not an SVG this Mac can draw")
            }
            return Picture(data: data, kind: .svg, size: image.size, isFullBleed: false)
        }
        if data.starts(with: Array("%PDF".utf8)) {
            guard let provider = CGDataProvider(data: data as CFData), let page = CGPDFDocument(provider)?.page(at: 1) else {
                throw LineRefusal("image `\(url.lastPathComponent)` is not a PDF this Mac can read")
            }
            return Picture(data: data, kind: .pdf, size: page.getBoxRect(.mediaBox).size, isFullBleed: false)
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw LineRefusal("image `\(url.lastPathComponent)` is not a PNG, JPEG, PDF or SVG")
        }
        let square = abs(image.width - image.height) <= max(image.width, image.height) / 50
        return Picture(data: data, kind: .bitmap, size: CGSize(width: image.width, height: image.height),
                       isFullBleed: square && image.width >= 256 && isOpaque(image))
    }

    /// Whether every pixel of `image`'s corners and edges is opaque.
    static func isOpaque(_ image: CGImage) -> Bool {
        switch image.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast: return true
        default: break
        }
        let side = 64
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let context = CGContext(data: &pixels, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        for y in 0..<side { for x in 0..<side where x == 0 || y == 0 || x == side - 1 || y == side - 1 {
            if pixels[(y * side + x) * 4 + 3] < 250 { return false }
        } }
        return true
    }

    /// The average colours of the picture's top and bottom halves: the ground a whole-icon picture gives a brand.
    func halves() -> [SRGBColor] {
        let side = 16
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let context = CGContext(data: &pixels, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.interpolationQuality = .high
        // A whole-icon picture is square, so aspect-fit fills the square.
        draw(in: CGRect(x: 0, y: 0, width: side, height: side), context: context)
        var colors: [SRGBColor] = []
        for half in 0..<2 {
            var sum = [0, 0, 0]
            // The buffer's first rows are the top of the picture.
            for y in (half * side / 2)..<((half + 1) * side / 2) {
                for x in 0..<side {
                    let base = (y * side + x) * 4
                    for channel in 0..<3 { sum[channel] += Int(pixels[base + channel]) }
                }
            }
            let count = side * side / 2
            colors.append(SRGBColor(red: (sum[0] + count / 2) / count, green: (sum[1] + count / 2) / count, blue: (sum[2] + count / 2) / count))
        }
        return colors
    }

    /// The picture aspect-fit and centred in `rect`.
    func draw(in rect: CGRect, context: CGContext) {
        let scale = min(rect.width / size.width, rect.height / size.height)
        let fitted = CGRect(x: rect.midX - size.width * scale / 2, y: rect.midY - size.height * scale / 2,
                            width: size.width * scale, height: size.height * scale)
        switch kind {
        case .bitmap:
            guard let source = CGImageSourceCreateWithData(data as CFData, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return }
            context.draw(image, in: fitted)
        case .pdf:
            guard let provider = CGDataProvider(data: data as CFData), let page = CGPDFDocument(provider)?.page(at: 1) else { return }
            let box = page.getBoxRect(.mediaBox)
            context.saveGState()
            context.translateBy(x: fitted.minX, y: fitted.minY)
            context.scaleBy(x: fitted.width / box.width, y: fitted.height / box.height)
            context.translateBy(x: -box.minX, y: -box.minY)
            context.drawPDFPage(page)
            context.restoreGState()
        case .svg:
            guard let image = NSImage(data: data) else { return }
            let previous = NSGraphicsContext.current
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            image.draw(in: fitted, from: .zero, operation: .sourceOver, fraction: 1)
            NSGraphicsContext.current = previous
        }
    }
}
