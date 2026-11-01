//  WHAT: The faces a brand is set in, from the font a call names: a family (`Avenir Next`), a face (`Futura-Bold`,
//        `Didot Bold`) or nothing (Avenir Next). The monogram takes the family's bold face and the wordmark one a
//        step lighter; a face named outright sets both.
//  PIN:  NEVER SF PRO, SF COMPACT, SF MONO OR NEW YORK. Apple's system fonts are licensed for the interface only,
//        not for icons or logos; a call that names one is refused, and a letter only they hold is refused too.

import CoreText
import Foundation

struct FontChoice: Equatable, Sendable {
    /// The PostScript name the monogram is set in.
    var monogram: String
    /// The PostScript name the wordmark is set in.
    var wordmark: String

    static let fallbackFamily = "Avenir Next"
    static let suggestions = "Avenir Next, Futura, Georgia, Didot, Gill Sans or Menlo"

    /// Whether `name` is one of Apple's system fonts, which no icon or logo may use.
    static func isSystemFont(_ name: String) -> Bool {
        let key = name.lowercased().filter { $0.isLetter || $0 == "." }
        if key.hasPrefix(".") || key.contains("applesystem") || key.hasPrefix("system") { return true }
        return ["sfpro", "sfcompact", "sfmono", "sfui", "sfarabic", "sfhebrew", "sfgeorgian", "sfarmenian", "sfns", "newyork"]
            .contains { key.hasPrefix($0) }
    }

    static func resolve(_ requested: String?) throws -> FontChoice {
        let name = (requested ?? fallbackFamily).trimmingCharacters(in: .whitespaces)
        guard !isSystemFont(name) else {
            throw LineRefusal("font `\(name)` is one of Apple's system fonts, whose licence keeps it out of icons and logos: name a bundled font such as \(suggestions)")
        }
        if let faces = family(name), !faces.isEmpty {
            return FontChoice(monogram: pick(faces, weight: 0.4), wordmark: pick(faces, weight: 0.3))
        }
        // A family and a style: `Futura Bold`, `Didot Italic`.
        let words = name.split(separator: " ").map(String.init)
        for cut in stride(from: words.count - 1, to: 0, by: -1) {
            let familyName = words[..<cut].joined(separator: " "), style = words[cut...].joined(separator: " ").lowercased()
            if let faces = family(familyName), let face = faces.first(where: { $0.style.lowercased().filter(\.isLetter) == style.filter(\.isLetter) }) {
                return FontChoice(monogram: face.postScript, wordmark: face.postScript)
            }
        }
        // A face by its PostScript or full name.
        let font = CTFontCreateWithName(name as CFString, 64, nil)
        let found = [CTFontCopyPostScriptName(font), CTFontCopyFullName(font), CTFontCopyDisplayName(font)].map { $0 as String }
        let wanted = name.lowercased().filter { $0.isLetter || $0.isNumber }
        if found.contains(where: { $0.lowercased().filter { $0.isLetter || $0.isNumber } == wanted }) {
            let postScript = CTFontCopyPostScriptName(font) as String
            guard !isSystemFont(postScript) else {
                throw LineRefusal("font `\(name)` is one of Apple's system fonts, whose licence keeps it out of icons and logos: name a bundled font such as \(suggestions)")
            }
            return FontChoice(monogram: postScript, wordmark: postScript)
        }
        throw LineRefusal("no font called `\(name)` is installed on this Mac: name one such as \(suggestions)")
    }

    struct Face { var postScript: String; var style: String; var weight: Double }

    /// The upright, normal-width faces of `name`, or nil when no family has that name.
    static func family(_ name: String) -> [Face]? {
        let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontFamilyNameAttribute: name] as CFDictionary)
        guard let matches = CTFontDescriptorCreateMatchingFontDescriptors(descriptor, nil) as? [CTFontDescriptor], !matches.isEmpty else { return nil }
        var faces: [Face] = []
        for match in matches {
            guard let family = CTFontDescriptorCopyAttribute(match, kCTFontFamilyNameAttribute) as? String,
                  family.caseInsensitiveCompare(name) == .orderedSame,
                  let postScript = CTFontDescriptorCopyAttribute(match, kCTFontNameAttribute) as? String else { continue }
            let style = (CTFontDescriptorCopyAttribute(match, kCTFontStyleNameAttribute) as? String) ?? ""
            let traits = (CTFontDescriptorCopyAttribute(match, kCTFontTraitsAttribute) as? [CFString: Any]) ?? [:]
            let weight = (traits[kCTFontWeightTrait] as? Double) ?? 0
            let symbolic = (traits[kCTFontSymbolicTrait] as? UInt32) ?? 0
            let slanted = symbolic & CTFontSymbolicTraits.traitItalic.rawValue != 0 || style.lowercased().contains("italic") || style.lowercased().contains("oblique")
            let narrow = symbolic & CTFontSymbolicTraits.traitCondensed.rawValue != 0 || style.lowercased().contains("condensed")
            if !slanted, !narrow, !isSystemFont(postScript) { faces.append(Face(postScript: postScript, style: style, weight: weight)) }
        }
        return faces.isEmpty ? nil : faces
    }

    /// The face closest to `weight` (CoreText's scale: regular 0, bold 0.4), a heavier one winning a tie.
    static func pick(_ faces: [Face], weight: Double) -> String {
        faces.min { a, b in
            let da = abs(a.weight - weight), db = abs(b.weight - weight)
            return abs(da - db) < 0.001 ? a.weight > b.weight : da < db
        }!.postScript
    }
}
