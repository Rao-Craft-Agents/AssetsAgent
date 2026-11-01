//  WHAT: The logo sets: `Logo` (the badge), `LogoMark` (the mark alone, a template that takes the tint of where it
//        sits), `Wordmark` (the name) and `Lockup` (badge and name), every one a vector PDF in light and dark but the
//        template, which has no colour of its own.
//  PIN:  COLOUR LOGOS RENDER AS DRAWN. Their sets say `original`, so a toolbar or a tab bar never flattens them
//        into its tint.

import Foundation

enum LogoSets {
    static func make(_ painter: LogoPainter) throws -> [CatalogSet] {
        [
            ImageSets.vector("Logo", light: painter.badge(.light, outline: .circle, side: 128), dark: painter.badge(.dark, outline: .circle, side: 128), rendering: "original"),
            ImageSets.vector("LogoMark", light: painter.mark(side: 64), dark: nil, rendering: "template"),
            ImageSets.vector("Wordmark", light: try painter.wordmark(.light, capHeight: 28), dark: try painter.wordmark(.dark, capHeight: 28), rendering: "original"),
            ImageSets.vector("Lockup", light: try painter.lockup(.light, height: 56), dark: try painter.lockup(.dark, height: 56), rendering: "original"),
        ]
    }

    /// `LaunchLogo`: the icon's rounded square, light and dark, at the size a launch screen shows it.
    static func launch(_ painter: LogoPainter) -> CatalogSet {
        ImageSets.vector("LaunchLogo", light: painter.badge(.light, outline: .squircle, side: 120), dark: painter.badge(.dark, outline: .squircle, side: 120), rendering: "original")
    }
}
