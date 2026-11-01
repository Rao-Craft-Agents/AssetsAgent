//  WHAT: What the project still needs for the assets a call wrote to show, read off its Xcode project and its
//        Info.plists, one sentence each: an app target that names no app icon, a watch app that must name its own,
//        a launch screen that does not name the launch logo.
//  PIN:  SAID, NEVER EDITED. The project file and the Info.plists belong to the agents that make them; this one
//        only says what to set.

import Foundation

enum ProjectWiring {
    static func notes(root: URL, sets: [AssetsSet], platforms: [AssetsPlatform], launchColor: Bool) -> [String] {
        var notes: [String] = []
        let manager = FileManager.default
        let names = (try? manager.contentsOfDirectory(atPath: root.path)) ?? []
        let projects = names.filter { $0.hasSuffix(".xcodeproj") }.compactMap {
            try? String(contentsOf: root.appendingPathComponent($0).appendingPathComponent("project.pbxproj"), encoding: .utf8)
        }
        if sets.contains(.icon) {
            if projects.contains(where: { $0.contains("com.apple.product-type.application") && !$0.contains("ASSETCATALOG_COMPILER_APPICON_NAME") }) {
                notes.append("the app targets set no ASSETCATALOG_COMPILER_APPICON_NAME, so the app shows no icon until each sets it to AppIcon")
            }
            if platforms.contains(.watchos) && platforms.contains(.macos) {
                notes.append("the watch icon is its own set, WatchAppIcon: the watch app's target sets ASSETCATALOG_COMPILER_APPICON_NAME to WatchAppIcon")
            }
        }
        if sets.contains(.launch), platforms.contains(.ios) {
            let plists = plistTexts(root)
            if !plists.contains(where: { $0.contains("LaunchLogo") }) {
                let color = launchColor ? " and UIColorName LaunchBackground" : ""
                notes.append("LaunchLogo shows at launch once the iOS app's Info.plist UILaunchScreen has UIImageName LaunchLogo\(color)")
            }
        }
        return notes
    }

    /// The text of every Info.plist two folders deep or less.
    private static func plistTexts(_ root: URL) -> [String] {
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return [] }
        var texts: [String] = []
        for case let url as URL in walker {
            if walker.level > 2 { walker.skipDescendants(); continue }
            if url.lastPathComponent.hasSuffix("Info.plist"), let text = try? String(contentsOf: url, encoding: .utf8) { texts.append(text) }
        }
        return texts
    }
}
