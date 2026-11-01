import Foundation

/// Why a line of a call, or one of its values, cannot be honoured: one sentence the model can act on.
struct LineRefusal: Error, Equatable, CustomStringConvertible {
    let reason: String

    init(_ reason: String) { self.reason = reason }

    var description: String { reason }
}
