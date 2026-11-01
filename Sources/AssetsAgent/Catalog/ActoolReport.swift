import Foundation

/// What actool said of a catalog it compiled.
struct ActoolReport: Sendable, Equatable {
    var errors: [String] = []
    var warnings: [String] = []
    var notices: [String] = []
    /// The files it wrote: the `Assets.car`, loose icons, the partial Info.plist.
    var outputs: [String] = []
}
