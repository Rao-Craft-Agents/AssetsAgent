//  WHAT: A symbol line, one custom symbol: a name and SVG path data in a 0…100 box, y down.
//
//            compose: M14 86 L30 82 L82 30 L70 18 L18 70 Z M62 26 L74 38
//            pin.fill: M50 92 C50 92 20 60 20 40 A30 30 0 0 1 80 40 C80 60 50 92 50 92 Z
//
//        The path is the symbol's centre line, stroked at each weight; a name ending `.fill` (or `fill` before the
//        colon) fills the path instead.

import Foundation

enum SymbolLine {
    static func parse(_ line: String) throws -> SymbolSpec {
        guard let head = LineHead.split(line), !head.rest.isEmpty else {
            throw LineRefusal("symbol line `\(line)` is not `name: path data in a 0…100 box`")
        }
        var name = head.name, filled = false
        if name.hasSuffix(" fill") { name = String(name.dropLast(5)).trimmingCharacters(in: .whitespaces); filled = true }
        if name.hasSuffix(".fill") { filled = true }
        guard name.range(of: #"^[A-Za-z0-9][A-Za-z0-9._-]*$"#, options: .regularExpression) != nil else {
            throw LineRefusal("symbol line `\(line)`: `\(name)` is not a symbol name (letters, digits, `.`, `_`, `-`)")
        }
        let path: SVGPath
        do { path = try SVGPath.parse(head.rest) } catch let refusal as LineRefusal {
            throw LineRefusal("symbol `\(name)`: \(refusal.reason)")
        }
        let bounds = path.bounds
        if bounds.minX < -2 || bounds.minY < -2 || bounds.maxX > 102 || bounds.maxY > 102 {
            throw LineRefusal("symbol `\(name)` reaches \(Int(bounds.minX.rounded())),\(Int(bounds.minY.rounded()))–\(Int(bounds.maxX.rounded())),\(Int(bounds.maxY.rounded())), outside its 0…100 box")
        }
        if bounds.width < 1, bounds.height < 1 {
            throw LineRefusal("symbol `\(name)` draws a single point")
        }
        return SymbolSpec(name: name, filled: filled, path: path)
    }
}
