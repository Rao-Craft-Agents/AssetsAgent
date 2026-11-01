//  WHAT: The eight geometric glyphs a mark can be, each built from circles, arcs and strokes with CoreGraphics'
//        path operations, in a unit box (y up): ring, knot, wave, spark, stack, leaf, bubble and grid. Each has a
//        small cut for icons 32 pixels and under: fewer parts, heavier strokes, wider gaps, so it still reads.
//  PIN:  GAPS ARE CUT, NEVER PAINTED. A gap is a hole in the outline (subtracted, or a strand left short), not a
//        stroke in the background's colour, so the mark stays one ink on any ground: a gradient, a dark icon, a
//        template that takes the tint of where it sits.

import CoreGraphics
import Foundation

enum Glyphs {
    static func layers(_ shape: AssetsShape, small: Bool) -> [MarkLayer] {
        switch shape {
        case .ring: return ring(small: small)
        case .knot: return knot(small: small)
        case .wave: return wave(small: small)
        case .spark: return spark(small: small)
        case .stack: return stack(small: small)
        case .leaf: return leaf(small: small)
        case .bubble: return bubble(small: small)
        case .grid: return grid(small: small)
        }
    }

    // MARK: - The glyphs

    /// A heavy ring broken where a satellite dot sits on it.
    static func ring(small: Bool) -> [MarkLayer] {
        let center = CGPoint(x: 0.5, y: 0.5), outer: CGFloat = 0.5, thickness: CGFloat = small ? 0.2 : 0.165
        let middle = outer - thickness / 2, angle = 40 * CGFloat.pi / 180
        let dotRadius: CGFloat = small ? 0.125 : 0.108, gap: CGFloat = small ? 0.06 : 0.045
        let dot = CGPoint(x: center.x + middle * cos(angle), y: center.y + middle * sin(angle))
        let band = circle(center, outer).subtracting(circle(center, outer - thickness)).subtracting(circle(dot, dotRadius + gap))
        return [MarkLayer(path: band, opacity: 1), MarkLayer(path: circle(dot, dotRadius), opacity: 1)]
    }

    /// A trefoil knot, its strand passing over and under in turn: the strand passing under is cut along the edges
    /// of the one passing over it, so each gap runs parallel to the strand that makes it.
    static func knot(small: Bool) -> [MarkLayer] {
        let count = 900
        let points = (0..<count).map { index -> CGPoint in
            let t = CGFloat(index) / CGFloat(count) * 2 * .pi
            return CGPoint(x: sin(t) + 2 * sin(2 * t), y: -(cos(t) - 2 * cos(2 * t)))
        }
        let width: CGFloat = small ? 0.95 : 0.74, gap: CGFloat = small ? 0.3 : 0.22
        // Where the strand crosses itself: each crossing is met twice, over the first time and under the next.
        var crossings: [(over: CGFloat, under: CGFloat)] = []
        var meetings: [(at: CGFloat, crossing: Int)] = []
        for i in 0..<count {
            let a = points[i], b = points[(i + 1) % count]
            for j in stride(from: i + 2, to: count, by: 1) where !(i == 0 && j == count - 1) {
                let c = points[j], d = points[(j + 1) % count]
                guard let (s, u) = intersection(a, b, c, d) else { continue }
                let here = CGFloat(i) + s, there = CGFloat(j) + u
                // A crossing on a shared vertex is found by both segments that meet there: keep it once.
                if meetings.contains(where: { abs($0.at - here) < 2 || abs($0.at - there) < 2 }) { continue }
                meetings += [(here, crossings.count), (there, crossings.count)]
                crossings.append((here, there))
            }
        }
        meetings.sort { $0.at < $1.at }
        for (order, meeting) in meetings.enumerated() where order % 2 == 0 {
            // Alternate along the strand: the even meetings pass over.
            let other = crossings[meeting.crossing].over == meeting.at ? crossings[meeting.crossing].under : crossings[meeting.crossing].over
            crossings[meeting.crossing] = (meeting.at, other)
        }
        let loop = CGMutablePath()
        loop.addLines(between: points)
        loop.closeSubpath()
        var outline = loop.copy(strokingWithWidth: width, lineCap: .butt, lineJoin: .round, miterLimit: 4)
        let step = (0..<count).reduce(CGFloat(0)) { $0 + points[$1].distance(to: points[($1 + 1) % count]) } / CGFloat(count)
        for crossing in crossings {
            // The stretch of the over strand that spans the under strand and its gaps, wider for a shallow crossing.
            let a = tangent(points, at: crossing.over), b = tangent(points, at: crossing.under)
            let sine = max(0.35, abs(a.x * b.y - a.y * b.x))
            let half = ((width / 2 + gap) / sine + width * 0.25) / step
            var stretch: [CGPoint] = []
            var t = crossing.over - half
            while t < crossing.over + half { stretch.append(point(points, at: t)); t += 1 }
            stretch.append(point(points, at: crossing.over + half))
            let line = CGMutablePath()
            line.addLines(between: stretch)
            let band = line.copy(strokingWithWidth: width + gap * 2, lineCap: .butt, lineJoin: .round, miterLimit: 4)
            let over = line.copy(strokingWithWidth: width, lineCap: .butt, lineJoin: .round, miterLimit: 4)
            outline = outline.subtracting(band).union(over)
        }
        return [MarkLayer(path: outline, opacity: 1)]
    }

    /// The unit direction of a closed polyline at a fractional index.
    static func tangent(_ points: [CGPoint], at index: CGFloat) -> CGPoint {
        let a = point(points, at: index - 1), b = point(points, at: index + 1)
        let length = max(a.distance(to: b), 1e-9)
        return CGPoint(x: (b.x - a.x) / length, y: (b.y - a.y) / length)
    }

    /// Three waves, the lower ones lighter; two in the small cut.
    static func wave(small: Bool) -> [MarkLayer] {
        let rows: [CGFloat] = small ? [0.68, 0.32] : [0.8, 0.5, 0.2]
        let opacities: [CGFloat] = small ? [1, 0.68] : [1, 0.7, 0.44]
        let width: CGFloat = small ? 0.17 : 0.125, amplitude: CGFloat = small ? 0.08 : 0.07
        return zip(rows, opacities).map { row, opacity in
            let line = CGMutablePath()
            line.addLines(between: stride(from: CGFloat(0.06), through: 0.94, by: 0.01).map { x in
                CGPoint(x: x, y: row + amplitude * sin((x - 0.06) / 0.44 * 2 * .pi))
            })
            return MarkLayer(path: line.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 4), opacity: opacity)
        }
    }

    /// A four-pointed spark, a small one at its shoulder.
    static func spark(small: Bool) -> [MarkLayer] {
        if small { return [MarkLayer(path: sparkle(CGPoint(x: 0.5, y: 0.5), 0.5, pinch: 0.24), opacity: 1)] }
        return [MarkLayer(path: sparkle(CGPoint(x: 0.4, y: 0.4), 0.4, pinch: 0.2), opacity: 1),
                MarkLayer(path: sparkle(CGPoint(x: 0.84, y: 0.84), 0.16, pinch: 0.2), opacity: 1)]
    }

    /// Three layers: a tile with two chevrons below it, each lighter than the one above.
    static func stack(small: Bool) -> [MarkLayer] {
        let top = rhombus(CGPoint(x: 0.5, y: small ? 0.64 : 0.7), halfWidth: 0.5, halfHeight: 0.27, radius: 0.05)
        var layers = [MarkLayer(path: top, opacity: 1)]
        let drop: CGFloat = small ? 0.27 : 0.2, width: CGFloat = small ? 0.14 : 0.095
        for level in 1...(small ? 1 : 2) {
            let y = (small ? 0.64 : 0.7) - drop * CGFloat(level)
            let line = CGMutablePath()
            line.addLines(between: [CGPoint(x: 0.04, y: y), CGPoint(x: 0.5, y: y - 0.25), CGPoint(x: 0.96, y: y)])
            layers.append(MarkLayer(path: line.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 4),
                                    opacity: level == 1 ? 0.72 : 0.46))
        }
        return layers
    }

    /// A leaf on a short stem, its midrib cut through it.
    static func leaf(small: Bool) -> [MarkLayer] {
        let blade = CGMutablePath()
        blade.move(to: CGPoint(x: 0, y: 0))
        blade.addCurve(to: CGPoint(x: 1, y: 0), control1: CGPoint(x: 0.16, y: 0.4), control2: CGPoint(x: 0.66, y: 0.42))
        blade.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: 0.72, y: -0.26), control2: CGPoint(x: 0.24, y: -0.3))
        blade.closeSubpath()
        let rib = CGMutablePath()
        rib.move(to: CGPoint(x: 0.1, y: 0.0))
        rib.addQuadCurve(to: CGPoint(x: small ? 0.7 : 0.8, y: 0.03), control: CGPoint(x: 0.45, y: 0.06))
        var leaf = blade.subtracting(rib.copy(strokingWithWidth: small ? 0.075 : 0.045, lineCap: .round, lineJoin: .round, miterLimit: 4))
        let stem = CGMutablePath()
        stem.move(to: CGPoint(x: 0.04, y: 0.0))
        stem.addQuadCurve(to: CGPoint(x: -0.16, y: -0.07), control: CGPoint(x: -0.06, y: -0.02))
        leaf = leaf.union(stem.copy(strokingWithWidth: small ? 0.085 : 0.06, lineCap: .round, lineJoin: .round, miterLimit: 4))
        let turn = CGAffineTransform(rotationAngle: .pi / 4)
        return [MarkLayer(path: leaf.copy(using: [turn]) ?? leaf, opacity: 1)]
    }

    /// A speech bubble with a tail and three dots cut through it.
    static func bubble(small: Bool) -> [MarkLayer] {
        let center = CGPoint(x: 0.53, y: 0.55), radius: CGFloat = 0.43
        func on(_ degrees: CGFloat) -> CGPoint {
            CGPoint(x: center.x + radius * cos(degrees * .pi / 180), y: center.y + radius * sin(degrees * .pi / 180))
        }
        let tail = CGMutablePath()
        tail.move(to: on(196))
        tail.addQuadCurve(to: CGPoint(x: 0.06, y: 0.06), control: CGPoint(x: 0.13, y: 0.26))
        tail.addQuadCurve(to: on(244), control: CGPoint(x: 0.24, y: 0.1))
        tail.closeSubpath()
        var body = circle(center, radius).union(tail)
        let dot: CGFloat = small ? 0.075 : 0.056, spacing: CGFloat = small ? 0.21 : 0.165
        for index in -1...1 {
            body = body.subtracting(circle(CGPoint(x: center.x + CGFloat(index) * spacing, y: center.y), dot))
        }
        return [MarkLayer(path: body, opacity: 1)]
    }

    /// Four tiles, the top right one round, the bottom right one lighter.
    static func grid(small: Bool) -> [MarkLayer] {
        let side: CGFloat = small ? 0.44 : 0.43, gap = 1 - 2 * side, radius = side * 0.3
        func tile(_ x: CGFloat, _ y: CGFloat) -> CGPath { Squircle.path(CGRect(x: x, y: y, width: side, height: side), radius: radius) }
        return [MarkLayer(path: tile(0, side + gap), opacity: 1),
                MarkLayer(path: circle(CGPoint(x: side + gap + side / 2, y: side + gap + side / 2), side / 2), opacity: 1),
                MarkLayer(path: tile(0, 0), opacity: 1),
                MarkLayer(path: tile(side + gap, 0), opacity: small ? 0.6 : 0.5)]
    }

    // MARK: - Parts

    static func circle(_ center: CGPoint, _ radius: CGFloat) -> CGPath {
        CGPath(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2), transform: nil)
    }

    /// A four-pointed star whose sides curve in towards its centre by `pinch`.
    static func sparkle(_ center: CGPoint, _ radius: CGFloat, pinch: CGFloat) -> CGPath {
        let k = pinch * radius
        let tips = [CGPoint(x: center.x, y: center.y + radius), CGPoint(x: center.x + radius, y: center.y),
                    CGPoint(x: center.x, y: center.y - radius), CGPoint(x: center.x - radius, y: center.y)]
        let path = CGMutablePath()
        path.move(to: tips[0])
        for index in 0..<4 {
            let from = tips[index], to = tips[(index + 1) % 4]
            path.addCurve(to: to, control1: CGPoint(x: center.x + (from.x - center.x) / radius * k, y: center.y + (from.y - center.y) / radius * k),
                          control2: CGPoint(x: center.x + (to.x - center.x) / radius * k, y: center.y + (to.y - center.y) / radius * k))
        }
        path.closeSubpath()
        return path
    }

    /// A rhombus, an isometric tile, its corners rounded by `radius`.
    static func rhombus(_ center: CGPoint, halfWidth: CGFloat, halfHeight: CGFloat, radius: CGFloat) -> CGPath {
        let corners = [CGPoint(x: center.x, y: center.y + halfHeight), CGPoint(x: center.x + halfWidth, y: center.y),
                       CGPoint(x: center.x, y: center.y - halfHeight), CGPoint(x: center.x - halfWidth, y: center.y)]
        let path = CGMutablePath()
        path.move(to: CGPoint(x: (corners[3].x + corners[0].x) / 2, y: (corners[3].y + corners[0].y) / 2))
        for index in 0..<4 {
            path.addArc(tangent1End: corners[index], tangent2End: corners[(index + 1) % 4], radius: radius)
        }
        path.closeSubpath()
        return path
    }

    /// Where segment ab meets segment cd, as the fraction along each; nil when they do not meet.
    static func intersection(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> (CGFloat, CGFloat)? {
        let r = CGPoint(x: b.x - a.x, y: b.y - a.y), s = CGPoint(x: d.x - c.x, y: d.y - c.y)
        let denominator = r.x * s.y - r.y * s.x
        guard abs(denominator) > 1e-12 else { return nil }
        let t = ((c.x - a.x) * s.y - (c.y - a.y) * s.x) / denominator
        let u = ((c.x - a.x) * r.y - (c.y - a.y) * r.x) / denominator
        return (0...1).contains(t) && (0...1).contains(u) ? (t, u) : nil
    }

    /// The point a fractional index along a closed polyline names.
    static func point(_ points: [CGPoint], at index: CGFloat) -> CGPoint {
        let count = points.count
        let wrapped = (index.truncatingRemainder(dividingBy: CGFloat(count)) + CGFloat(count)).truncatingRemainder(dividingBy: CGFloat(count))
        let base = Int(wrapped), fraction = wrapped - CGFloat(base)
        let a = points[base % count], b = points[(base + 1) % count]
        return CGPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
    }
}
