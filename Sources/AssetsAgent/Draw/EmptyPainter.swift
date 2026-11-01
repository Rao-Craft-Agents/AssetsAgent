//  WHAT: Empty-state illustrations as vector PDFs, light and dark: an open inbox tray with a card in it, a
//        magnifier, a cloud struck through, a warning sign. Each a few geometric shapes on a soft disc of the
//        brand's tint, in the brand's colour and two neutrals.
//  PIN:  ONE HAND FOR ALL FOUR. The same disc, the same stroke weight, the same three tones and the same sparks,
//        so the four read as one set beside the app's own type.

import CoreGraphics
import Foundation

struct EmptyPainter {
    let brand: Brand

    enum Scene: String, CaseIterable { case inbox = "Inbox", search = "Search", offline = "Offline", error = "Error" }

    /// `scene`, `side` points square.
    func draw(_ scene: Scene, dark: Bool, side: CGFloat) -> Data {
        VectorPage.pdf(width: side, height: side) { context in
            context.scaleBy(x: side / 160, y: side / 160)
            let tones = Palette(brand.tones, dark: dark)
            context.setFillColor(tones.disc.cgColor)
            context.addPath(Glyphs.circle(CGPoint(x: 80, y: 80), 66))
            context.fillPath()
            switch scene {
            case .inbox: inbox(tones, context)
            case .search: search(tones, context)
            case .offline: offline(tones, context)
            case .error: warning(tones, context)
            }
        }
    }

    /// The three tones and the paper an illustration is drawn in.
    struct Palette {
        var disc: SRGBColor, figure: SRGBColor, deep: SRGBColor, paper: SRGBColor, line: SRGBColor
        init(_ tones: BrandTones, dark: Bool) {
            disc = tones.tint(dark: dark)
            figure = tones.figure(dark: dark)
            let f = figure.oklch
            deep = OKLCH(l: f.l + (dark ? -0.1 : -0.12), c: f.c, h: f.h + 4).rgb
            paper = dark ? tones.neutral(0.42) : .white
            line = dark ? tones.neutral(0.6) : tones.neutral(0.86)
        }
    }

    private func fill(_ path: CGPath, _ color: SRGBColor, _ context: CGContext) {
        context.addPath(path)
        context.setFillColor(color.cgColor)
        context.fillPath()
    }

    private func line(_ points: [CGPoint], width: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points)
        return path.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 4)
    }

    private func sparks(_ tones: Palette, _ context: CGContext) {
        fill(Glyphs.sparkle(CGPoint(x: 126, y: 122), 7, pinch: 0.22), tones.figure.with(alpha: 0.75), context)
        fill(Glyphs.circle(CGPoint(x: 36, y: 112), 3.2), tones.figure.with(alpha: 0.55), context)
        fill(Glyphs.circle(CGPoint(x: 120, y: 40), 2.4), tones.figure.with(alpha: 0.45), context)
    }

    private func inbox(_ tones: Palette, _ context: CGContext) {
        // A card standing in the tray, tilted, with three lines of text.
        context.saveGState()
        context.translateBy(x: 80, y: 86)
        context.rotate(by: -0.12)
        fill(Squircle.path(CGRect(x: -26, y: -16, width: 52, height: 50), radius: 7), tones.paper, context)
        for (index, width) in [34.0, 26, 30].enumerated() {
            fill(line([CGPoint(x: -17, y: 22 - CGFloat(index) * 10), CGPoint(x: -17 + width, y: 22 - CGFloat(index) * 10)], width: 4.5), tones.line, context)
        }
        context.restoreGState()
        // The tray: its back, then its front with the dip a hand reaches into.
        fill(Squircle.path(CGRect(x: 36, y: 40, width: 88, height: 36), radius: 9), tones.deep, context)
        let front = Squircle.path(CGRect(x: 36, y: 34, width: 88, height: 32), radius: 9)
            .subtracting(Squircle.path(CGRect(x: 62, y: 52, width: 36, height: 30), radius: 8))
        fill(front, tones.figure, context)
        sparks(tones, context)
    }

    private func search(_ tones: Palette, _ context: CGContext) {
        let center = CGPoint(x: 72, y: 88)
        fill(Glyphs.circle(center, 26), tones.paper.with(alpha: 0.9), context)
        fill(line([CGPoint(x: 92, y: 68), CGPoint(x: 114, y: 46)], width: 13), tones.deep, context)
        fill(Glyphs.circle(center, 31).subtracting(Glyphs.circle(center, 22)), tones.figure, context)
        let glint = CGMutablePath()
        glint.addArc(center: center, radius: 14, startAngle: .pi * 0.62, endAngle: .pi * 0.95, clockwise: false)
        fill(glint.copy(strokingWithWidth: 4.5, lineCap: .round, lineJoin: .round, miterLimit: 4), tones.line, context)
        sparks(tones, context)
    }

    private func offline(_ tones: Palette, _ context: CGContext) {
        var cloud = Squircle.path(CGRect(x: 38, y: 56, width: 86, height: 30), radius: 15)
        for (x, y, r) in [(64.0, 86.0, 19.0), (88, 94, 24), (108, 84, 16)] {
            cloud = cloud.union(Glyphs.circle(CGPoint(x: x, y: y), r))
        }
        let slash = [CGPoint(x: 48, y: 42), CGPoint(x: 116, y: 118)]
        cloud = cloud.subtracting(line(slash, width: 18))
        fill(cloud, tones.figure, context)
        fill(line(slash, width: 8), tones.deep, context)
        sparks(tones, context)
    }

    private func warning(_ tones: Palette, _ context: CGContext) {
        let corners = [CGPoint(x: 80, y: 120), CGPoint(x: 122, y: 46), CGPoint(x: 38, y: 46)]
        let sign = CGMutablePath()
        sign.move(to: CGPoint(x: (corners[2].x + corners[0].x) / 2, y: (corners[2].y + corners[0].y) / 2))
        for index in 0..<3 { sign.addArc(tangent1End: corners[index], tangent2End: corners[(index + 1) % 3], radius: 11) }
        sign.closeSubpath()
        let mark = line([CGPoint(x: 80, y: 96), CGPoint(x: 80, y: 74)], width: 9).union(Glyphs.circle(CGPoint(x: 80, y: 61), 5.2))
        fill(sign.subtracting(mark), tones.figure, context)
        sparks(tones, context)
    }
}
