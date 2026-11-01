import Foundation

/// The kinds of asset a call can make.
public enum AssetsSet: String, Codable, Sendable, CaseIterable {
    /// `AppIcon`: every size and appearance the call's platforms need.
    case icon
    /// `AccentColor`, light and dark.
    case accent
    /// One colour set a `palette` line.
    case colors
    /// `Logo`, `LogoMark`, `Wordmark` and `Lockup`, as vector PDFs.
    case logos
    /// `LaunchLogo`.
    case launch
    /// `Placeholder/Avatar` and a few sample avatars.
    case placeholders
    /// Empty-state illustrations: `Empty/Inbox`, `Empty/Search`, `Empty/Offline`, `Empty/Error`.
    case empty
    /// One symbol set a `symbols` line.
    case symbols
    /// One data set a `data` line.
    case data
}
