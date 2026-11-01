//  WHAT: Bitmaps the icons are drawn into and the PNGs they become: sRGB, opaque (no alpha channel, what an iOS
//        icon must be) or with alpha (a macOS icon's transparent margin), a pixel a unit, y up.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum Raster {
    /// A `width` × `height` image drawn by `draw`.
    static func image(width: Int, height: Int, opaque: Bool, draw: (CGContext) -> Void) -> CGImage {
        let info = opaque ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info)!
        context.interpolationQuality = .high
        context.setShouldAntialias(true)
        if !opaque { context.clear(CGRect(x: 0, y: 0, width: width, height: height)) }
        draw(context)
        return context.makeImage()!
    }

    /// `image` with every colour turned to the grey of its lightness: what a tinted icon is.
    static func desaturated(_ image: CGImage, opaque: Bool) -> CGImage {
        let grey = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
                             space: CGColorSpace(name: CGColorSpace.linearGray)!, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        grey.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let flat = grey.makeImage()!
        return Self.image(width: image.width, height: image.height, opaque: opaque) { $0.draw(flat, in: CGRect(x: 0, y: 0, width: image.width, height: image.height)) }
    }

    static func png(_ image: CGImage) -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        return data as Data
    }
}
