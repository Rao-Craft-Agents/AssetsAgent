import CoreGraphics

extension CGPoint {
    /// How far `other` is, in a straight line.
    func distance(to other: CGPoint) -> CGFloat { hypot(other.x - x, other.y - y) }
}
