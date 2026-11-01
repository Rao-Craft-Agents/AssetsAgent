import Foundation

/// The platforms an app icon is drawn for.
public enum AssetsPlatform: String, Codable, Sendable, CaseIterable {
    case ios
    case macos
    case watchos
    case visionos
}
