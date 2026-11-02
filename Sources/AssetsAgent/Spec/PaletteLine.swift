//  WHAT: A palette line, one colour set:
//
//            brand: #A19A8E/#CFCAC1          light, then dark
//            surface: #FFFFFF / #121212
//            ink: #1D1B19                    the same in both
//            danger: #D93A2B/#FF6B5E/#A3180D/#FFA39A   light, dark, then each in high contrast
//
//        A name, a colon (or `=`), and one, two or four hex colours split by `/`.
//  PIN:  A LINE THAT IS NOT UNDERSTOOD IS REFUSED WITH THE REASON; a guessed colour would ship in the app.

import Foundation

enum PaletteLine {
    static func parse(_ line: String) throws -> PaletteColor {
        guard let head = LineHead.split(line), !head.rest.isEmpty else {
            throw LineRefusal("palette line `\(line)` is not `name: #light/#dark`")
        }
        // `colors/background` is a set in a namespace folder, as a kit reads it by `Color("colors/background")`.
        let segments = head.name.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard segments.count <= 3, segments.allSatisfy(LineHead.isAssetName) else {
            throw LineRefusal("palette line `\(line)`: `\(head.name)` is not a colour name (a letter, then letters, digits, `_`, `-` or `.`; `group/name` for a set in a namespace)")
        }
        let words = head.rest.split(whereSeparator: { $0 == "/" || $0 == "|" || $0 == " " || $0 == "," }).map(String.init)
        var colors: [SRGBColor] = []
        for word in words {
            guard let color = SRGBColor(hex: word) else { throw LineRefusal("palette line `\(line)`: `\(word)` is not a hex colour like #A19A8E") }
            colors.append(color)
        }
        switch colors.count {
        case 1: return PaletteColor(name: head.name, light: colors[0])
        case 2: return PaletteColor(name: head.name, light: colors[0], dark: colors[1])
        case 4: return PaletteColor(name: head.name, light: colors[0], dark: colors[1], lightHigh: colors[2], darkHigh: colors[3])
        default:
            throw LineRefusal("palette line `\(line)` gives \(colors.count) colours: give one, light/dark, or light/dark/light high contrast/dark high contrast")
        }
    }
}
