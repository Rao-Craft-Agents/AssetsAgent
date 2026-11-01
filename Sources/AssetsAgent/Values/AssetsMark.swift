import Foundation

/// What the brand's mark is drawn from.
public enum AssetsMark: String, Codable, Sendable, CaseIterable {
    /// One to three letters set in a bundled macOS font: the default.
    case monogram
    /// A geometric glyph drawn on the Mac (`AssetsShape`).
    case shape
    /// A picture the project already has: a PNG, JPEG, PDF or SVG.
    case image
}
