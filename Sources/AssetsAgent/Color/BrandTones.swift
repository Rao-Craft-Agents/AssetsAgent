//  WHAT: Every colour the brand's assets are drawn in, derived from the few a call gives (the icon's background,
//        the mark's colour, the accent): the icon's light and dark looks, the accent for light and dark, the ink a
//        wordmark is set in, and the soft tints illustrations and placeholders are drawn with.
//  PIN:  DARK IS THE BRAND'S HUE AT NIGHT, NEVER A GREY. Every dark tone keeps the brand's hue at low lightness and
//        chroma, so the dark icon and the dark logos are still the brand's.
//  PIN:  CONTRAST IS MEASURED, NOT HOPED FOR. The accent is moved in lightness until it reads on white (light) and
//        on black (dark); a mark that is left with less than 3:1 on its background is told in a note.

import Foundation

struct BrandTones: Sendable, Equatable {
    /// The light icon's background, top to bottom: one colour (solid) or two or three (a gradient).
    var background: [SRGBColor]
    /// The mark on the light icon.
    var mark: SRGBColor
    /// The brand's own colour: the most saturated of its background and mark, what the dark looks are lit by.
    var vivid: SRGBColor
    /// The dark icon's background, top to bottom.
    var darkBackground: [SRGBColor]
    /// The mark on the dark icon.
    var darkMark: SRGBColor
    /// The brand's text colour on a light page, and on a dark one.
    var ink: SRGBColor
    var darkInk: SRGBColor
    /// The accent, light and dark.
    var accent: SRGBColor
    var darkAccent: SRGBColor

    /// The tones of a brand whose icon background is `background` (1–3 stops), with its mark in `foreground`
    /// (else white or ink, by contrast) and its accent `accent` (else made from the brand's colour).
    static func derive(background: [SRGBColor], foreground: SRGBColor?, accent: (light: SRGBColor, dark: SRGBColor?)?) -> BrandTones {
        let stops = background.isEmpty ? [SRGBColor(red: 0x5E, green: 0x6A, blue: 0xD2)] : background
        let middle = Self.middle(of: stops)
        let hueSource = stops.max { $0.oklch.c < $1.oklch.c }!
        let hue = hueSource.oklch.h, chroma = hueSource.oklch.c
        let ink = OKLCH(l: 0.25, c: min(chroma, 0.045), h: hue).rgb
        let mark = foreground ?? (middle.contrast(with: .white) >= 3 || middle.contrast(with: .white) >= middle.contrast(with: ink) ? .white : ink)
        // A coloured mark more saturated than its ground is the brand's colour; otherwise the ground is.
        let vivid = mark != .white && mark != ink && mark.oklch.c > chroma ? mark : hueSource
        let v = vivid.oklch

        let darkBackground = [OKLCH(l: 0.29, c: min(v.c, 0.05), h: v.h - 4).rgb, OKLCH(l: 0.17, c: min(v.c, 0.04), h: v.h + 6).rgb]
        let darkMark = v.c < 0.03 ? OKLCH(l: 0.93, c: v.c, h: v.h).rgb : OKLCH(l: max(v.l, 0.76), c: min(v.c, 0.15), h: v.h).rgb

        let light = accent?.light ?? readable(vivid, on: .white, ratio: 3.6)
        let dark = accent?.dark ?? accent.map { readable($0.light, on: .black, ratio: 5) } ?? readable(vivid, on: .black, ratio: 5)
        return BrandTones(background: stops, mark: mark, vivid: vivid, darkBackground: darkBackground, darkMark: darkMark,
                          ink: ink, darkInk: OKLCH(l: 0.96, c: min(v.c, 0.018), h: v.h).rgb, accent: light, darkAccent: dark)
    }

    /// `color` moved in lightness until it reaches `ratio` against `page`, its hue and chroma kept.
    static func readable(_ color: SRGBColor, on page: SRGBColor, ratio: Double) -> SRGBColor {
        var tone = color.oklch
        let step = page.isDark ? 0.01 : -0.01
        var result = color
        for _ in 0..<100 where result.contrast(with: page) < ratio {
            tone = tone.with(l: tone.l + step)
            result = tone.rgb
            if tone.l <= 0 || tone.l >= 1 { break }
        }
        return result
    }

    /// The contrast of the light icon's mark on the ground behind it: the middle of the gradient, where it sits.
    var markContrast: Double { Self.middle(of: background).contrast(with: mark) }

    /// The colour halfway down a gradient of `stops`.
    static func middle(of stops: [SRGBColor]) -> SRGBColor {
        guard stops.count > 1 else { return stops.first ?? .white }
        if stops.count % 2 == 1 { return stops[stops.count / 2] }
        return stops[stops.count / 2 - 1].mixed(with: stops[stops.count / 2], 0.5)
    }

    // MARK: - Tints for illustrations and placeholders

    /// A soft tint of the brand: what an illustration's backdrop and a placeholder's ground are drawn in.
    func tint(dark: Bool) -> SRGBColor {
        let v = vivid.oklch
        return dark ? OKLCH(l: 0.31, c: min(v.c, 0.05), h: v.h).rgb : OKLCH(l: 0.935, c: min(v.c, 0.035), h: v.h).rgb
    }

    /// The brand's colour as an illustration's main stroke: readable on the page it sits on.
    func figure(dark: Bool) -> SRGBColor {
        dark ? Self.readable(vivid, on: SRGBColor(red: 0x1C, green: 0x1C, blue: 0x1E), ratio: 3.2)
             : Self.readable(vivid, on: .white, ratio: 3.2)
    }

    /// A neutral of the brand's hue at `lightness`, barely tinted.
    func neutral(_ lightness: Double) -> SRGBColor {
        OKLCH(l: lightness, c: min(vivid.oklch.c, 0.012), h: vivid.oklch.h).rgb
    }
}
