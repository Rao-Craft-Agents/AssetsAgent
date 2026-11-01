import Foundation

/// What a call can say instead of writing.
public enum AssetsError: Error, Equatable, CustomStringConvertible {
    /// Every part of the call that cannot be honoured, one sentence each, so all are fixed in one call.
    case refused([String])
    /// The catalog did not compile, and actool's reasons.
    case uncompiled([String])

    public var description: String {
        switch self {
        case .refused(let reasons):
            let count = reasons.count == 1 ? "1 part of the call" : "\(reasons.count) parts of the call"
            return "\(count) cannot be honoured, so nothing was written:\n" + reasons.map { "- \($0)" }.joined(separator: "\n")
        case .uncompiled(let reasons):
            return "the asset catalog does not compile, so nothing was written:\n" + reasons.map { "- \($0)" }.joined(separator: "\n")
        }
    }
}
