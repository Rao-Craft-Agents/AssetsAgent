import Foundation

/// A platform actool compiles a catalog for: its SDK name, the lowest OS the app runs on, its devices, and the
/// app icon it is asked to pick.
struct ActoolTarget: Sendable, Equatable {
    var platform: String
    var deployment: String
    var devices: [String]
    var appIcon: String?

    /// The target for one of the agent's platforms: iOS 17, macOS 14, watchOS 10, visionOS 1.
    static func of(_ platform: AssetsPlatform, appIcon: String?) -> ActoolTarget {
        switch platform {
        case .ios: return ActoolTarget(platform: "iphoneos", deployment: "17.0", devices: ["iphone", "ipad"], appIcon: appIcon)
        case .macos: return ActoolTarget(platform: "macosx", deployment: "14.0", devices: [], appIcon: appIcon)
        case .watchos: return ActoolTarget(platform: "watchos", deployment: "10.0", devices: ["watch"], appIcon: appIcon)
        case .visionos: return ActoolTarget(platform: "xros", deployment: "1.0", devices: ["vision"], appIcon: appIcon)
        }
    }
}
