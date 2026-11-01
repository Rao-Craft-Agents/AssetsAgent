//  WHAT: The colour sets: `AccentColor` (the app's tint, light and dark) and one set a palette line, each with its
//        high-contrast colours when the call asks for them.
//  PIN:  HIGH CONTRAST PUSHES AWAY FROM THE MIDDLE. A derived high-contrast colour goes darker in light appearance
//        and lighter in dark, unless it is a page (very light in light, very dark in dark), which goes further out:
//        either way text and its page move apart.

import Foundation

enum ColorSets {
    static func accent(light: SRGBColor, dark: SRGBColor, contrast: Bool) -> CatalogSet {
        set(name: "AccentColor", PaletteColor(name: "AccentColor", light: light, dark: dark), contrast: contrast)
    }

    static func palette(_ color: PaletteColor, contrast: Bool) -> CatalogSet {
        set(name: color.name, color, contrast: contrast)
    }

    private static func set(name: String, _ color: PaletteColor, contrast: Bool) -> CatalogSet {
        var entries: [(appearance: CatalogAppearance?, color: SRGBColor)] = [(nil, color.light)]
        if let dark = color.dark { entries.append((.dark, dark)) }
        if contrast || color.lightHigh != nil {
            entries.append((.highContrast, color.lightHigh ?? highContrast(color.light, dark: false)))
            if let dark = color.dark { entries.append((.darkHighContrast, color.darkHigh ?? highContrast(dark, dark: true))) }
        }
        return CatalogSet(folder: "\(name).colorset", name: name, files: [.contents(CatalogContents.colorSet(entries))])
    }

    /// `color` with more contrast, for the light (`dark` false) or the dark appearance.
    static func highContrast(_ color: SRGBColor, dark: Bool) -> SRGBColor {
        let tone = color.oklch
        let page = dark ? tone.l < 0.3 : tone.l > 0.85
        let step = dark ? (page ? -0.07 : 0.1) : (page ? 0.06 : -0.1)
        return tone.with(l: min(1, max(0, tone.l + step))).rgb(alpha: color.alpha)
    }
}
