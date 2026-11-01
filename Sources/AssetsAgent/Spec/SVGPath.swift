//  WHAT: SVG path data (`M10 90 L90 10 C…`: every command, absolute and relative, arcs turned into curves) read into
//        subpaths of lines and cubic curves in absolute coordinates: what a symbol line draws in its 0…100 box.
//  PIN:  A PATH THAT IS NOT UNDERSTOOD IS REFUSED, saying where it stopped making sense.

import CoreGraphics
import Foundation

struct SVGPath: Equatable, Sendable {
    enum Segment: Equatable, Sendable {
        case line(CGPoint)
        case cubic(CGPoint, CGPoint, CGPoint)

        var end: CGPoint {
            switch self {
            case .line(let point): return point
            case .cubic(_, _, let point): return point
            }
        }
    }

    struct Subpath: Equatable, Sendable {
        var start: CGPoint
        var segments: [Segment]
        var closed: Bool
    }

    var subpaths: [Subpath]

    /// The path as CoreGraphics draws it, through `transform`.
    func cgPath(_ transform: CGAffineTransform = .identity) -> CGPath {
        let path = CGMutablePath()
        for subpath in subpaths {
            path.move(to: subpath.start, transform: transform)
            for segment in subpath.segments {
                switch segment {
                case .line(let point): path.addLine(to: point, transform: transform)
                case .cubic(let c1, let c2, let point): path.addCurve(to: point, control1: c1, control2: c2, transform: transform)
                }
            }
            if subpath.closed { path.closeSubpath() }
        }
        return path
    }

    /// The tight bounds of what the path draws.
    var bounds: CGRect { cgPath().boundingBoxOfPath }

    /// Each subpath as points along it: a curve in steps set by its own length, never by how it is drawn, so the
    /// same path gives the same points at every weight.
    func polylines() -> [(points: [CGPoint], closed: Bool)] {
        subpaths.map { subpath in
            var points = [subpath.start], previous = subpath.start
            for segment in subpath.segments {
                switch segment {
                case .line(let point):
                    points.append(point)
                case .cubic(let c1, let c2, let end):
                    let length = previous.distance(to: c1) + c1.distance(to: c2) + c2.distance(to: end)
                    let steps = max(4, min(48, Int((length / 3).rounded(.up))))
                    for step in 1...steps {
                        let t = CGFloat(step) / CGFloat(steps), u = 1 - t
                        points.append(CGPoint(x: u * u * u * previous.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * end.x,
                                              y: u * u * u * previous.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * end.y))
                    }
                }
                previous = segment.end
            }
            var deduped: [CGPoint] = []
            for point in points where deduped.last.map({ $0.distance(to: point) > 0.001 }) ?? true { deduped.append(point) }
            if subpath.closed, deduped.count > 1, deduped.first!.distance(to: deduped.last!) <= 0.001 { deduped.removeLast() }
            return (deduped, subpath.closed)
        }
    }

    // MARK: - Reading

    static func parse(_ text: String) throws -> SVGPath {
        var reader = Reader(bytes: Array(text.utf8))
        var subpaths: [Subpath] = []
        var current: Subpath?
        var point = CGPoint.zero, start = CGPoint.zero
        var lastCubic: CGPoint?, lastQuad: CGPoint?
        var command: UInt8?

        func finish() { if let open = current, !open.segments.isEmpty { subpaths.append(open) }; current = nil }
        func add(_ segment: Segment) {
            if current == nil { current = Subpath(start: point, segments: [], closed: false) }
            current!.segments.append(segment)
            point = segment.end
        }

        while true {
            reader.skipSeparators()
            if reader.atEnd { break }
            if let letter = reader.command() {
                command = letter
            } else if command == nil {
                throw LineRefusal("path data starts with `\(reader.rest)`, and it must start with M")
            }
            guard let letter = command else { break }
            let relative = letter >= 97
            let base = relative ? point : .zero
            func pair() throws -> CGPoint {
                guard let x = reader.number(), let y = reader.number() else { throw LineRefusal("path data wants two numbers at `\(reader.rest)`") }
                return CGPoint(x: base.x + x, y: base.y + y)
            }
            func one() throws -> CGFloat {
                guard let value = reader.number() else { throw LineRefusal("path data wants a number at `\(reader.rest)`") }
                return value
            }
            var cubicControl: CGPoint?, quadControl: CGPoint?
            switch letter | 0x20 {
            case UInt8(ascii: "m"):
                let target = try pair()
                finish()
                point = target; start = target
                current = Subpath(start: target, segments: [], closed: false)
                command = relative ? UInt8(ascii: "l") : UInt8(ascii: "L")
            case UInt8(ascii: "l"):
                add(.line(try pair()))
            case UInt8(ascii: "h"):
                let x = try one()
                add(.line(CGPoint(x: relative ? point.x + x : x, y: point.y)))
            case UInt8(ascii: "v"):
                let y = try one()
                add(.line(CGPoint(x: point.x, y: relative ? point.y + y : y)))
            case UInt8(ascii: "c"):
                let c1 = try pair(), c2 = try pair(), end = try pair()
                add(.cubic(c1, c2, end)); cubicControl = c2
            case UInt8(ascii: "s"):
                let c1 = lastCubic.map { CGPoint(x: 2 * point.x - $0.x, y: 2 * point.y - $0.y) } ?? point
                let c2 = try pair(), end = try pair()
                add(.cubic(c1, c2, end)); cubicControl = c2
            case UInt8(ascii: "q"):
                let control = try pair(), end = try pair()
                add(Self.quadratic(from: point, control, end)); quadControl = control
            case UInt8(ascii: "t"):
                let control = lastQuad.map { CGPoint(x: 2 * point.x - $0.x, y: 2 * point.y - $0.y) } ?? point
                let end = try pair()
                add(Self.quadratic(from: point, control, end)); quadControl = control
            case UInt8(ascii: "a"):
                let rx = try one(), ry = try one(), rotation = try one()
                guard let large = reader.flag(), let sweep = reader.flag() else { throw LineRefusal("path data wants arc flags (0 or 1) at `\(reader.rest)`") }
                let end = try pair()
                for segment in Self.arc(from: point, rx: rx, ry: ry, rotation: rotation, large: large, sweep: sweep, to: end) { add(segment) }
                if point != end { point = end }
            case UInt8(ascii: "z"):
                if var open = current {
                    open.closed = true
                    if !open.segments.isEmpty { subpaths.append(open) }
                    current = nil
                }
                point = start
                command = nil
            default:
                throw LineRefusal("path data has `\(Character(UnicodeScalar(letter)))`, which is not an SVG path command")
            }
            lastCubic = cubicControl
            lastQuad = quadControl
        }
        finish()
        guard !subpaths.isEmpty else { throw LineRefusal("path data draws nothing") }
        return SVGPath(subpaths: subpaths)
    }

    private static func quadratic(from start: CGPoint, _ control: CGPoint, _ end: CGPoint) -> Segment {
        .cubic(CGPoint(x: start.x + 2 / 3 * (control.x - start.x), y: start.y + 2 / 3 * (control.y - start.y)),
               CGPoint(x: end.x + 2 / 3 * (control.x - end.x), y: end.y + 2 / 3 * (control.y - end.y)), end)
    }

    /// An SVG elliptical arc as cubic curves of a quarter turn or less (SVG 1.1, appendix F.6).
    static func arc(from start: CGPoint, rx: CGFloat, ry: CGFloat, rotation: CGFloat, large: Bool, sweep: Bool, to end: CGPoint) -> [Segment] {
        if start == end { return [] }
        var rx = abs(rx), ry = abs(ry)
        if rx == 0 || ry == 0 { return [.line(end)] }
        let phi = rotation * .pi / 180, cosPhi = cos(phi), sinPhi = sin(phi)
        let dx = (start.x - end.x) / 2, dy = (start.y - end.y) / 2
        let x1 = cosPhi * dx + sinPhi * dy, y1 = -sinPhi * dx + cosPhi * dy
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 { rx *= lambda.squareRoot(); ry *= lambda.squareRoot() }
        let numerator = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let denominator = rx * rx * y1 * y1 + ry * ry * x1 * x1
        let coefficient = (large != sweep ? 1 : -1) * (max(0, numerator / denominator)).squareRoot()
        let cxp = coefficient * rx * y1 / ry, cyp = coefficient * -ry * x1 / rx
        let cx = cosPhi * cxp - sinPhi * cyp + (start.x + end.x) / 2
        let cy = sinPhi * cxp + cosPhi * cyp + (start.y + end.y) / 2
        func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat { atan2(ux * vy - uy * vx, ux * vx + uy * vy) }
        let theta = angle(1, 0, (x1 - cxp) / rx, (y1 - cyp) / ry)
        var delta = angle((x1 - cxp) / rx, (y1 - cyp) / ry, (-x1 - cxp) / rx, (-y1 - cyp) / ry)
        if !sweep && delta > 0 { delta -= 2 * .pi } else if sweep && delta < 0 { delta += 2 * .pi }
        let count = max(1, Int((abs(delta) / (.pi / 2)).rounded(.up)))
        let step = delta / CGFloat(count), k = 4 / 3 * tan(step / 4)
        func at(_ t: CGFloat) -> CGPoint {
            CGPoint(x: cx + rx * cosPhi * cos(t) - ry * sinPhi * sin(t), y: cy + rx * sinPhi * cos(t) + ry * cosPhi * sin(t))
        }
        func slope(_ t: CGFloat) -> CGPoint {
            CGPoint(x: -rx * cosPhi * sin(t) - ry * sinPhi * cos(t), y: -rx * sinPhi * sin(t) + ry * cosPhi * cos(t))
        }
        var segments: [Segment] = []
        for index in 0..<count {
            let a = theta + CGFloat(index) * step, b = a + step
            let p0 = at(a), p1 = index == count - 1 ? end : at(b), d0 = slope(a), d1 = slope(b)
            segments.append(.cubic(CGPoint(x: p0.x + k * d0.x, y: p0.y + k * d0.y), CGPoint(x: p1.x - k * d1.x, y: p1.y - k * d1.y), p1))
        }
        return segments
    }

    /// A cursor over path data: commands, numbers in every form SVG allows (`-.5.5e2`), and arc flags.
    private struct Reader {
        let bytes: [UInt8]
        var index = 0

        var atEnd: Bool { index >= bytes.count }
        var rest: String { String(decoding: bytes[min(index, bytes.count)...].prefix(24), as: UTF8.self) }

        mutating func skipSeparators() {
            while index < bytes.count, [32, 9, 10, 13, 44].contains(bytes[index]) { index += 1 }
        }

        mutating func command() -> UInt8? {
            guard index < bytes.count else { return nil }
            let byte = bytes[index]
            guard "MmLlHhVvCcSsQqTtAaZz".utf8.contains(byte) else {
                if (65...90).contains(byte) || (97...122).contains(byte), byte != UInt8(ascii: "e"), byte != UInt8(ascii: "E") {
                    return byte  // a letter that is not a command: the caller names it
                }
                return nil
            }
            index += 1
            return byte
        }

        mutating func number() -> CGFloat? {
            skipSeparators()
            let begin = index
            func digit(_ i: Int) -> Bool { i < bytes.count && (48...57).contains(bytes[i]) }
            if index < bytes.count, bytes[index] == 43 || bytes[index] == 45 { index += 1 }
            var any = false
            while digit(index) { index += 1; any = true }
            if index < bytes.count, bytes[index] == 46 { index += 1; while digit(index) { index += 1; any = true } }
            guard any else { index = begin; return nil }
            if index < bytes.count, bytes[index] == 101 || bytes[index] == 69 {
                var look = index + 1
                if look < bytes.count, bytes[look] == 43 || bytes[look] == 45 { look += 1 }
                if digit(look) { index = look; while digit(index) { index += 1 } }
            }
            return Double(String(decoding: bytes[begin..<index], as: UTF8.self)).map { CGFloat($0) }
        }

        mutating func flag() -> Bool? {
            skipSeparators()
            guard index < bytes.count, bytes[index] == 48 || bytes[index] == 49 else { return nil }
            defer { index += 1 }
            return bytes[index] == 49
        }
    }
}
