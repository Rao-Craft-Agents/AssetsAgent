import Foundation

/// One colour set a palette line names: its colour in light, and in dark and high contrast when the line gives them.
struct PaletteColor: Equatable, Sendable {
    var name: String
    var light: SRGBColor
    var dark: SRGBColor?
    var lightHigh: SRGBColor?
    var darkHigh: SRGBColor?
}
