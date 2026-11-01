//  WHAT: Text as outlines: the glyphs of a monogram or a wordmark set by CoreText (kerned, tracked, no ligatures)
//        and turned into one CGPath, so a logo carries shapes rather than a font, and is centred by its ink.
//  PIN:  NO FALLBACK. A character the face lacks would be set by macOS in another font, often SF Pro, whose licence
//        keeps it out of logos; such text is refused instead, naming bundled fonts that have every character.

import CoreGraphics
import CoreText
import Foundation

enum TextOutline {
    /// The outlines of `text` in the face `font` at `size` points, tracked by `tracking` ems, baseline at y 0.
    static func path(_ text: String, font: String, size: CGFloat, tracking: CGFloat = 0) throws -> CGPath {
        let face = CTFontCreateWithName(font as CFString, size, nil)
        let attributes: [CFString: Any] = [kCTFontAttributeName: face, kCTKernAttributeName: tracking * size, kCTLigatureAttributeName: 0]
        let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary))
        let path = CGMutablePath()
        let runs = (CTLineGetGlyphRuns(line) as? [CTRun]) ?? []
        let wanted = CTFontCopyPostScriptName(face) as String
        for run in runs {
            let runAttributes = CTRunGetAttributes(run) as NSDictionary
            let runFont = runAttributes[kCTFontAttributeName] as! CTFont
            guard CTFontCopyPostScriptName(runFont) as String == wanted else {
                let family = CTFontCopyFamilyName(face) as String
                let others = families(holding: text).filter { $0 != family }
                let suggestion = others.isEmpty ? "choose letters it has" : "choose letters it has, or a font that has them: \(others.joined(separator: ", "))"
                throw LineRefusal("`\(text)` has a character \(family) does not, and macOS would set it in another font: \(suggestion)")
            }
            let count = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: count), positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)
            for (glyph, position) in zip(glyphs, positions) {
                var place = CGAffineTransform(translationX: position.x, y: position.y)
                if let outline = CTFontCreatePathForGlyph(runFont, glyph, &place) { path.addPath(outline) }
            }
        }
        return path
    }

    /// The bundled families, of those the guide suggests, that hold every character of `text`.
    static func families(holding text: String) -> [String] {
        ["Avenir Next", "Futura", "Georgia", "Palatino", "Iowan Old Style", "Didot", "Gill Sans", "Menlo"].filter { family in
            let font = CTFontCreateWithName(family as CFString, 12, nil)
            var characters = Array(text.utf16)
            var glyphs = [CGGlyph](repeating: 0, count: characters.count)
            return CTFontGetGlyphsForCharacters(font, &characters, &glyphs, characters.count)
        }
    }

    /// The cap height of `font` at `size`, what a wordmark is sized by.
    static func capHeight(font: String, size: CGFloat) -> CGFloat {
        CTFontGetCapHeight(CTFontCreateWithName(font as CFString, size, nil))
    }
}
