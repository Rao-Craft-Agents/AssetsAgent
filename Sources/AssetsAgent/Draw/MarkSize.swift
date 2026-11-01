import Foundation

/// The optical size a mark is cut for: an icon's own drawing at 32 pixels and under is simpler than at 1024.
enum MarkSize: Sendable, Equatable {
    /// 64 pixels and up: every part.
    case regular
    /// 32 pixels: fewer parts, heavier strokes, wider gaps.
    case small
    /// 16 pixels: the small cut, a monogram down to its first letter, set larger still.
    case tiny
}
