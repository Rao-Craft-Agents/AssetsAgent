import Foundation

/// What the brand's mark is drawn from. A shape's own name (`spark`, `knot`, …) draws that shape: what a call means
/// when it names the glyph where the kind of mark goes.
public enum AssetsMark: String, Codable, Sendable, CaseIterable {
    /// One to three letters set in a bundled macOS font: the default.
    case monogram
    /// A geometric glyph drawn on the Mac (`AssetsShape`).
    case shape
    /// A picture the project already has: a PNG, JPEG, PDF or SVG.
    case image
    case ring, knot, wave, spark, stack, leaf, bubble, grid

    /// The shape a shape's own name draws; nil for monogram, shape and image.
    var namedShape: AssetsShape? { AssetsShape(rawValue: rawValue) }
}
