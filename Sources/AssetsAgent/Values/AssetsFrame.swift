import Foundation

/// What a run says as it goes.
public enum AssetsFrame: Sendable {
    /// The call was read: how many sets it makes.
    case planned(sets: Int)
    /// The catalog is written.
    case written(AssetsResult)

    public var result: AssetsResult? {
        if case .written(let result) = self { return result }
        return nil
    }
}
