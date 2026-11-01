import Foundation

/// One symbol set a symbol line names: its name, whether its path is filled or stroked, and the path.
struct SymbolSpec: Equatable, Sendable {
    var name: String
    var filled: Bool
    var path: SVGPath
}
