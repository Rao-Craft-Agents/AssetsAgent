//  WHAT: The app icon sets: `AppIcon.appiconset` (iOS's single size in any, dark and tinted, macOS's ten sizes,
//        watchOS's single size), `AppIcon.solidimagestack` for visionOS (front, middle and back layers), and
//        `WatchAppIcon.appiconset` when one catalog serves both a Mac app and a watch app.
//  PIN:  A WATCH ICON BESIDE MAC SIZES IS UNASSIGNED ON THE MAC. actool, building for macOS, warns of a watchOS
//        slot in a set that also holds Mac sizes; such a catalog gives the watch its own set.

import Foundation

enum IconSets {
    static let macSizes = [16, 32, 128, 256, 512]

    static func make(_ painter: IconPainter, platforms: [AssetsPlatform]) -> [CatalogSet] {
        var sets: [CatalogSet] = []
        var files: [CatalogFile] = []
        var ios: [(appearance: CatalogAppearance?, file: String)] = []
        var mac: [(points: Int, scale: Int, file: String)] = []
        var watch: String?
        if platforms.contains(.ios) {
            for (appearance, look, file) in [(nil, IconPainter.Look.light, "icon-ios.png"), (.dark, .dark, "icon-ios-dark.png"), (.tinted, .tinted, "icon-ios-tinted.png")] as [(CatalogAppearance?, IconPainter.Look, String)] {
                files.append(CatalogFile(path: file, data: painter.ios(look)))
                ios.append((appearance, file))
            }
        }
        if platforms.contains(.macos) {
            var drawn: [Int: Data] = [:]
            for points in macSizes {
                for scale in [1, 2] {
                    let pixels = points * scale
                    let file = scale == 1 ? "icon-mac-\(points).png" : "icon-mac-\(points)@2x.png"
                    let data = drawn[pixels] ?? painter.mac(pixels: pixels)
                    drawn[pixels] = data
                    files.append(CatalogFile(path: file, data: data))
                    mac.append((points, scale, file))
                }
            }
        }
        let separateWatch = platforms.contains(.watchos) && platforms.contains(.macos)
        if platforms.contains(.watchos) {
            let image = CatalogFile(path: "icon-watch.png", data: painter.watch())
            if separateWatch {
                sets.append(CatalogSet(folder: "WatchAppIcon.appiconset", name: "WatchAppIcon", files: [
                    .contents(CatalogContents.appIcon(ios: [], mac: [], watch: image.path)), image,
                ]))
            } else {
                files.append(image)
                watch = image.path
            }
        }
        if !ios.isEmpty || !mac.isEmpty || watch != nil {
            sets.insert(CatalogSet(folder: "AppIcon.appiconset", name: "AppIcon",
                                   files: [.contents(CatalogContents.appIcon(ios: ios, mac: mac, watch: watch))] + files), at: 0)
        }
        if platforms.contains(.visionos) {
            let layers = ["Front", "Middle", "Back"]
            var stack: [CatalogFile] = [.contents(CatalogContents.solidImageStack(layers: layers))]
            for (layer, data) in zip(layers, painter.vision()) {
                let folder = "\(layer).solidimagestacklayer"
                let file = "\(layer.lowercased()).png"
                stack += [.contents(CatalogContents.stackLayer, at: "\(folder)/Contents.json"),
                          .contents(CatalogContents.stackLayerContent(file: file), at: "\(folder)/Content.imageset/Contents.json"),
                          CatalogFile(path: "\(folder)/Content.imageset/\(file)", data: data)]
            }
            sets.append(CatalogSet(folder: "AppIcon.solidimagestack", name: "AppIcon", files: stack))
        }
        return sets
    }
}
