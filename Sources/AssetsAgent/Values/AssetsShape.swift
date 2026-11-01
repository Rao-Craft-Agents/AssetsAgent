import Foundation

/// The geometric glyphs a mark can be, each drawn with CoreGraphics from circles, arcs and lines.
public enum AssetsShape: String, Codable, Sendable, CaseIterable {
    /// A heavy ring broken by a satellite dot.
    case ring
    /// A trefoil knot, its strands woven over and under.
    case knot
    /// Three waves, the lower ones lighter.
    case wave
    /// A four-pointed spark with a small one beside it.
    case spark
    /// Three layers stacked: a tile and two chevrons.
    case stack
    /// A leaf with its midrib cut through it.
    case leaf
    /// A speech bubble with three dots.
    case bubble
    /// Four tiles, one of them round.
    case grid
}
