import CoreGraphics

/// One part of a mark: a filled outline in the mark's unit box (y up), drawn at an opacity of the mark's ink.
struct MarkLayer {
    var path: CGPath
    var opacity: CGFloat
}
