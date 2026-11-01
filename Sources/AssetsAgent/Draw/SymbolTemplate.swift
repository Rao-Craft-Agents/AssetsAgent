//  WHAT: A custom symbol as an SF Symbols template (v3): the 3300 × 2200 artboard, its guides (the baseline and
//        capline of each scale, the margins of each weight drawn), and the symbol drawn at Ultralight, Regular and
//        Black in the small scale, from which Xcode makes every weight and scale. `Image("compose")` then draws it
//        beside text at any weight, as SF Symbols do.
//  PIN:  THE SAME OUTLINE AT EVERY WEIGHT. Xcode interpolates by pairing the points of the three drawings one to
//        one, so a stroked path is drawn as one capsule a segment: the same commands at every width.
//  PIN:  HOLES BY WINDING. The symbol compiler fills by the non-zero rule whatever the SVG says, so a filled path's
//        holes are turned to wind against the shape that holds them.
//  PIN:  NOTHING OF APPLE'S. The template holds the guides and notes Xcode reads and nothing drawn from Apple's
//        fonts or symbols.

import CoreGraphics
import Foundation

enum SymbolTemplate {
    /// The three weights drawn: their column's centre on the artboard and their stroke, in units of a 100-point symbol.
    static let weights: [(name: String, column: CGFloat, stroke: CGFloat)] = [
        ("Ultralight", 559.711, 2.0), ("Regular", 1449.84, 7.0), ("Black", 2933.4, 12.5),
    ]
    static let baselines: [(scale: String, baseline: CGFloat, capline: CGFloat)] = [
        ("S", 696, 625.541), ("M", 1126, 1055.54), ("L", 1556, 1485.54),
    ]
    /// The 0…100 box is drawn 88 units tall, centred on the middle of the capitals beside it.
    static let unit: CGFloat = 0.88
    static let top: CGFloat = -(70.459 / 2) - 44
    /// The room either side of the ink, inside the margins.
    static let bearing: CGFloat = 3.5

    /// The template's text.
    static func svg(_ symbol: SymbolSpec) -> String {
        var guides: [String] = [], groups: [String] = []
        for weight in weights.reversed() {
            let (data, ink) = drawing(symbol, stroke: weight.stroke)
            let width = ink.width + bearing * 2
            let left = weight.column - width / 2, right = weight.column + width / 2
            guides.append(#"  <line id="left-margin-\#(weight.name)-S" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;" x1="\#(n(left))" x2="\#(n(left))" y1="600.785" y2="720.121"/>"#)
            guides.append(#"  <line id="right-margin-\#(weight.name)-S" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;" x1="\#(n(right))" x2="\#(n(right))" y1="600.785" y2="720.121"/>"#)
            let shift = CGAffineTransform(translationX: bearing - ink.minX, y: 0)
            groups.append("""
              <g id="\(weight.name)-S" transform="matrix(1 0 0 1 \(n(left)) 696)">
               <path d="\(pathData(data, shift))"/>
              </g>
            """)
        }
        let labels = ["Ultralight": 559.711, "Thin": 856.422, "Light": 1153.13, "Regular": 1449.84, "Medium": 1746.56,
                      "Semibold": 2043.27, "Bold": 2339.98, "Heavy": 2636.69, "Black": 2933.4]
            .sorted { $0.value < $1.value }
            .map { #"  <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:middle;" transform="matrix(1 0 0 1 \#(n(CGFloat($0.value))) 322)">\#($0.key)</text>"# }
        let lines = baselines.flatMap { scale in [
            #"  <line id="Baseline-\#(scale.scale)" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="\#(n(scale.baseline))" y2="\#(n(scale.baseline))"/>"#,
            #"  <line id="Capline-\#(scale.scale)" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="\#(n(scale.capline))" y2="\#(n(scale.capline))"/>"#,
        ] }
        let note = #"style="stroke:none;fill:black;font-family:sans-serif;font-size:13;"#
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE svg
        PUBLIC "-//W3C//DTD SVG 1.1//EN"
               "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
        <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="3300" height="2200">
         <!--glyph: "\(symbol.name)", point size: 100.0, template writer: AssetsAgent-->
         <g id="Notes">
          <rect height="2200" id="artboard" style="fill:white;opacity:1" width="3300" x="0" y="0"/>
          <line style="fill:none;stroke:black;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="292" y2="292"/>
          <text \(note)font-weight:bold;" transform="matrix(1 0 0 1 263 322)">Weight/Scale Variations</text>
        \(labels.joined(separator: "\n"))
          <line style="fill:none;stroke:black;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="1903" y2="1903"/>
          <text \(note)font-weight:bold;" transform="matrix(1 0 0 1 263 1953)">Design Variations</text>
          <text \(note)" transform="matrix(1 0 0 1 263 1971)">Drawn at Ultralight, Regular and Black in the small scale; Xcode makes the rest.</text>
          <text id="template-version" \(note)text-anchor:end;" transform="matrix(1 0 0 1 3036 1933)">Template v.3.0</text>
          <text \(note)text-anchor:end;" transform="matrix(1 0 0 1 3036 1951)">Requires Xcode 13 or greater</text>
          <text id="descriptive-name" \(note)text-anchor:end;" transform="matrix(1 0 0 1 3036 1969)">Generated from \(escaped(symbol.name))</text>
          <text \(note)text-anchor:end;" transform="matrix(1 0 0 1 3036 1987)">Typeset at 100 points</text>
          <text \(note)" transform="matrix(1 0 0 1 263 726)">Small</text>
          <text \(note)" transform="matrix(1 0 0 1 263 1156)">Medium</text>
          <text \(note)" transform="matrix(1 0 0 1 263 1586)">Large</text>
         </g>
         <g id="Guides">
        \(lines.joined(separator: "\n"))
        \(guides.joined(separator: "\n"))
         </g>
         <g id="Symbols">
        \(groups.joined(separator: "\n"))
         </g>
        </svg>

        """
    }

    /// The symbol drawn at `stroke` in symbol units (y down, baseline at 0), and its ink's bounds.
    static func drawing(_ symbol: SymbolSpec, stroke: CGFloat) -> (CGPath, CGRect) {
        let place = CGAffineTransform(translationX: 0, y: top).scaledBy(x: unit, y: unit)
        if symbol.filled {
            let path = windingHoles(symbol.path.cgPath(place))
            return (path, path.boundingBoxOfPath)
        }
        let path = CGMutablePath()
        for line in symbol.path.polylines() {
            let points = line.points.map { $0.applying(place) }
            if points.count == 1 { addCapsule(points[0], points[0], width: stroke, to: path); continue }
            for index in 0..<(points.count - 1) { addCapsule(points[index], points[index + 1], width: stroke, to: path) }
            if line.closed, points.count > 2 { addCapsule(points[points.count - 1], points[0], width: stroke, to: path) }
        }
        return (path, path.boundingBoxOfPath)
    }

    /// A segment from `a` to `b` stroked `width` wide with round ends: two sides and two half circles, always
    /// eight curves and two lines, wound the same way.
    static func addCapsule(_ a: CGPoint, _ b: CGPoint, width: CGFloat, to path: CGMutablePath) {
        let length = a.distance(to: b)
        let d = length < 1e-6 ? CGPoint(x: 1, y: 0) : CGPoint(x: (b.x - a.x) / length, y: (b.y - a.y) / length)
        let n = CGPoint(x: -d.y, y: d.x), h = width / 2, k: CGFloat = 0.5522847498 * h
        func at(_ c: CGPoint, _ u: CGPoint, _ s: CGFloat) -> CGPoint { CGPoint(x: c.x + u.x * s, y: c.y + u.y * s) }
        func plus(_ p: CGPoint, _ u: CGPoint, _ s: CGFloat) -> CGPoint { CGPoint(x: p.x + u.x * s, y: p.y + u.y * s) }
        path.move(to: at(a, n, h))
        path.addLine(to: at(b, n, h))
        path.addCurve(to: at(b, d, h), control1: plus(at(b, n, h), d, k), control2: plus(at(b, d, h), n, k))
        path.addCurve(to: at(b, n, -h), control1: plus(at(b, d, h), n, -k), control2: plus(at(b, n, -h), d, k))
        path.addLine(to: at(a, n, -h))
        path.addCurve(to: at(a, d, -h), control1: plus(at(a, n, -h), d, -k), control2: plus(at(a, d, -h), n, -k))
        path.addCurve(to: at(a, n, h), control1: plus(at(a, d, -h), n, k), control2: plus(at(a, n, h), d, -k))
        path.closeSubpath()
    }

    /// `path` with each subpath wound by how deep it sits inside the others: shapes one way, their holes the
    /// other, so the non-zero rule fills what the even-odd rule would.
    static func windingHoles(_ path: CGPath) -> CGPath {
        var subpaths: [[(CGPathElementType, [CGPoint])]] = []
        path.applyWithBlock { pointer in
            let element = pointer.pointee
            let count: Int
            switch element.type {
            case .moveToPoint: count = 1; subpaths.append([])
            case .addLineToPoint: count = 1
            case .addQuadCurveToPoint: count = 2
            case .addCurveToPoint: count = 3
            case .closeSubpath: count = 0
            @unknown default: count = 0
            }
            if subpaths.isEmpty { subpaths.append([]) }
            subpaths[subpaths.count - 1].append((element.type, (0..<count).map { element.points[$0] }))
        }
        func outline(_ elements: [(CGPathElementType, [CGPoint])]) -> [CGPoint] { elements.flatMap { $0.1 } }
        func area(_ points: [CGPoint]) -> CGFloat {
            guard points.count > 2 else { return 0 }
            return (0..<points.count).reduce(CGFloat(0)) { sum, i in
                let a = points[i], b = points[(i + 1) % points.count]
                return sum + a.x * b.y - b.x * a.y
            } / 2
        }
        let shapes = subpaths
        let result = CGMutablePath()
        for (index, elements) in shapes.enumerated() {
            let points = outline(elements)
            guard let probe = points.first else { continue }
            let depth = shapes.indices.filter { other in
                other != index && contains(outline(shapes[other]), probe)
            }.count
            let wantsPositive = depth % 2 == 0
            let reversed = (area(points) > 0) != wantsPositive
            append(elements, reversed: reversed, to: result)
        }
        return result
    }

    private static func contains(_ polygon: [CGPoint], _ point: CGPoint) -> Bool {
        guard polygon.count > 2 else { return false }
        var inside = false, j = polygon.count - 1
        for i in 0..<polygon.count {
            let a = polygon[i], b = polygon[j]
            if (a.y > point.y) != (b.y > point.y), point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x { inside.toggle() }
            j = i
        }
        return inside
    }

    /// Appends one subpath's elements, backwards when `reversed`.
    private static func append(_ elements: [(CGPathElementType, [CGPoint])], reversed: Bool, to path: CGMutablePath) {
        guard let first = elements.first?.1.first else { return }
        let closed = elements.contains { $0.0 == .closeSubpath }
        if !reversed {
            path.move(to: first)
            for (type, points) in elements.dropFirst() {
                switch type {
                case .addLineToPoint: path.addLine(to: points[0])
                case .addQuadCurveToPoint: path.addQuadCurve(to: points[1], control: points[0])
                case .addCurveToPoint: path.addCurve(to: points[2], control1: points[0], control2: points[1])
                default: break
                }
            }
            if closed { path.closeSubpath() }
            return
        }
        // Walk the segments from the end: each one's start is the previous one's end.
        var segments: [(CGPathElementType, [CGPoint], CGPoint)] = []
        var current = first
        for (type, points) in elements.dropFirst() where type != .closeSubpath {
            segments.append((type, points, current))
            current = points.last ?? current
        }
        if closed, current != first { segments.append((.addLineToPoint, [first], current)) }
        path.move(to: current)
        for (type, points, start) in segments.reversed() {
            switch type {
            case .addLineToPoint: path.addLine(to: start)
            case .addQuadCurveToPoint: path.addQuadCurve(to: start, control: points[0])
            case .addCurveToPoint: path.addCurve(to: start, control1: points[1], control2: points[0])
            default: break
            }
        }
        if closed { path.closeSubpath() }
    }

    /// SVG path data for `path` through `transform`.
    static func pathData(_ path: CGPath, _ transform: CGAffineTransform) -> String {
        var parts: [String] = []
        path.applyWithBlock { pointer in
            let element = pointer.pointee
            func p(_ index: Int) -> String {
                let point = element.points[index].applying(transform)
                return "\(n(point.x)) \(n(point.y))"
            }
            switch element.type {
            case .moveToPoint: parts.append("M\(p(0))")
            case .addLineToPoint: parts.append("L\(p(0))")
            case .addQuadCurveToPoint: parts.append("Q\(p(0)) \(p(1))")
            case .addCurveToPoint: parts.append("C\(p(0)) \(p(1)) \(p(2))")
            case .closeSubpath: parts.append("Z")
            @unknown default: break
            }
        }
        return parts.joined(separator: "")
    }

    /// A number as the template writes it: at most three decimals, no trailing zeros.
    static func n(_ value: CGFloat) -> String {
        var text = String(format: "%.3f", Double(value))
        while text.contains("."), text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text == "-0" ? "0" : text
    }

    private static func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }
}
