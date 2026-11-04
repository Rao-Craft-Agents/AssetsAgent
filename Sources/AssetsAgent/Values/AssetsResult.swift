import Foundation
import GraniteAgents

/// What a call answers: the files written, as absolute paths, and the sets they make.
public struct AssetsResult: AgentAnswer, Equatable {
    /// The file to look at first: the largest app icon when the call drew one, else the first file written.
    public var path: String?
    /// Every file written: each set's images and its `Contents.json`.
    public var paths: [String]
    /// The asset catalog, absolute.
    public var catalog: String
    /// The assets made, by the names code uses (`AppIcon`, `AccentColor`, `Placeholder/Avatar`).
    public var sets: [String]
    /// One sentence each: what the project still needs, and what was left out and why.
    public var notes: [String]

    public init(path: String?, paths: [String], catalog: String, sets: [String], notes: [String]) {
        self.path = path; self.paths = paths; self.catalog = catalog; self.sets = sets; self.notes = notes
    }
}
