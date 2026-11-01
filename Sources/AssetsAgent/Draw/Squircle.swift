//  WHAT: A rounded rectangle with Apple's continuous corners: each corner's curve starts 1.528 radii before it and
//        eases into the side, so there is none of the kink a circular arc leaves where it meets a straight edge.
//        The shape of a macOS icon and of every badge the agent draws.

import CoreGraphics

enum Squircle {
    static func path(_ rect: CGRect, radius: CGFloat) -> CGPath {
        let r = min(radius, min(rect.width, rect.height) / 2 / 1.52866483)
        let (x0, x1, y0, y1) = (rect.minX, rect.maxX, rect.minY, rect.maxY)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
        let path = CGMutablePath()
        path.move(to: p(x0 + 1.52866483 * r, y0))
        path.addLine(to: p(x1 - 1.52866471 * r, y0))
        path.addCurve(to: p(x1 - 0.66993427 * r, y0 + 0.06549600 * r), control1: p(x1 - 1.08849323 * r, y0), control2: p(x1 - 0.86840689 * r, y0))
        path.addCurve(to: p(x1 - 0.06549569 * r, y0 + 0.66993493 * r), control1: p(x1 - 0.36745892 * r, y0 + 0.17605399 * r), control2: p(x1 - 0.17605382 * r, y0 + 0.36745873 * r))
        path.addCurve(to: p(x1, y0 + 1.52866483 * r), control1: p(x1, y0 + 0.86840701 * r), control2: p(x1, y0 + 1.08849299 * r))
        path.addLine(to: p(x1, y1 - 1.52866471 * r))
        path.addCurve(to: p(x1 - 0.06549600 * r, y1 - 0.66993427 * r), control1: p(x1, y1 - 1.08849323 * r), control2: p(x1, y1 - 0.86840689 * r))
        path.addCurve(to: p(x1 - 0.66993493 * r, y1 - 0.06549569 * r), control1: p(x1 - 0.17605399 * r, y1 - 0.36745892 * r), control2: p(x1 - 0.36745873 * r, y1 - 0.17605382 * r))
        path.addCurve(to: p(x1 - 1.52866483 * r, y1), control1: p(x1 - 0.86840701 * r, y1), control2: p(x1 - 1.08849299 * r, y1))
        path.addLine(to: p(x0 + 1.52866471 * r, y1))
        path.addCurve(to: p(x0 + 0.66993427 * r, y1 - 0.06549600 * r), control1: p(x0 + 1.08849323 * r, y1), control2: p(x0 + 0.86840689 * r, y1))
        path.addCurve(to: p(x0 + 0.06549569 * r, y1 - 0.66993493 * r), control1: p(x0 + 0.36745892 * r, y1 - 0.17605399 * r), control2: p(x0 + 0.17605382 * r, y1 - 0.36745873 * r))
        path.addCurve(to: p(x0, y1 - 1.52866483 * r), control1: p(x0, y1 - 0.86840701 * r), control2: p(x0, y1 - 1.08849299 * r))
        path.addLine(to: p(x0, y0 + 1.52866471 * r))
        path.addCurve(to: p(x0 + 0.06549600 * r, y0 + 0.66993427 * r), control1: p(x0, y0 + 1.08849323 * r), control2: p(x0, y0 + 0.86840689 * r))
        path.addCurve(to: p(x0 + 0.66993493 * r, y0 + 0.06549569 * r), control1: p(x0 + 0.17605399 * r, y0 + 0.36745892 * r), control2: p(x0 + 0.36745873 * r, y0 + 0.17605382 * r))
        path.addCurve(to: p(x0 + 1.52866483 * r, y0), control1: p(x0 + 0.86840701 * r, y0), control2: p(x0 + 1.08849299 * r, y0))
        path.closeSubpath()
        return path
    }
}
