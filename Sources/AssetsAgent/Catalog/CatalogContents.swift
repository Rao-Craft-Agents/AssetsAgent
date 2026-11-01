//  WHAT: The `Contents.json` of every kind of set the agent writes, in the shape Xcode 27 writes for it: the
//        catalog and its folders, an app icon set (iOS single size in three appearances, the ten macOS sizes, the
//        watchOS single size), a visionOS layered icon, a colour set, an image set, a symbol set and a data set.
//  PIN:  XCODE'S ORDER. Entries are listed in the order Xcode lists them (any, dark, tinted; then macOS from
//        16 pt up, 1x before 2x; normal contrast before high), so a set reads as if Xcode had written it.

import Foundation

enum CatalogContents {
    static let info: CatalogJSON = .object(["author": .string("xcode"), "version": .int(1)])

    /// The catalog's own `Contents.json`.
    static var catalog: CatalogJSON { .object(["info": info]) }

    /// A folder inside the catalog; one that provides a namespace makes its sets' names `Folder/Name`.
    static func group(namespace: Bool) -> CatalogJSON {
        namespace ? .object(["info": info, "properties": .object(["provides-namespace": .bool(true)])]) : .object(["info": info])
    }

    /// An app icon set. `ios`: the 1024 single-size images by appearance; `mac`: (points, scale, file) for each
    /// of the ten macOS sizes; `watch`: the watchOS single-size image.
    static func appIcon(ios: [(appearance: CatalogAppearance?, file: String)], mac: [(points: Int, scale: Int, file: String)],
                        watch: String?) -> CatalogJSON {
        var images: [CatalogJSON] = []
        for item in ios {
            var entry: [String: CatalogJSON] = ["filename": .string(item.file), "idiom": .string("universal"),
                                                "platform": .string("ios"), "size": .string("1024x1024")]
            if let appearance = item.appearance { entry["appearances"] = appearance.json }
            images.append(.object(entry))
        }
        for item in mac {
            images.append(.object(["filename": .string(item.file), "idiom": .string("mac"), "scale": .string("\(item.scale)x"),
                                   "size": .string("\(item.points)x\(item.points)")]))
        }
        if let watch {
            images.append(.object(["filename": .string(watch), "idiom": .string("universal"), "platform": .string("watchos"),
                                   "size": .string("1024x1024")]))
        }
        return .object(["images": .array(images), "info": info])
    }

    /// A visionOS app icon: its layers, front to back.
    static func solidImageStack(layers: [String]) -> CatalogJSON {
        .object(["info": info, "layers": .array(layers.map { .object(["filename": .string("\($0).solidimagestacklayer")]) })])
    }

    /// One layer of a visionOS app icon.
    static var stackLayer: CatalogJSON { .object(["info": info]) }

    /// The image of a visionOS icon layer: 1024 pixels, at 2x.
    static func stackLayerContent(file: String) -> CatalogJSON {
        .object(["images": .array([.object(["filename": .string(file), "idiom": .string("vision"), "scale": .string("2x")])]), "info": info])
    }

    /// A colour set: an sRGB colour for each appearance, any appearance first.
    static func colorSet(_ colors: [(appearance: CatalogAppearance?, color: SRGBColor)]) -> CatalogJSON {
        let entries: [CatalogJSON] = colors.map { item in
            var entry: [String: CatalogJSON] = ["color": item.color.catalogJSON, "idiom": .string("universal")]
            if let appearance = item.appearance { entry["appearances"] = appearance.json }
            return .object(entry)
        }
        return .object(["colors": .array(entries), "info": info])
    }

    /// An image set of single-scale images (vector PDFs), one an appearance. `vector` keeps the PDF's vectors at
    /// every size; `template` draws it in the tint of where it sits, `original` as drawn, nil as the context decides.
    static func imageSet(_ images: [(appearance: CatalogAppearance?, file: String)], vector: Bool, rendering: String?) -> CatalogJSON {
        let entries: [CatalogJSON] = images.map { item in
            var entry: [String: CatalogJSON] = ["filename": .string(item.file), "idiom": .string("universal")]
            if let appearance = item.appearance { entry["appearances"] = appearance.json }
            return .object(entry)
        }
        var properties: [String: CatalogJSON] = [:]
        if vector { properties["preserves-vector-representation"] = .bool(true) }
        if let rendering { properties["template-rendering-intent"] = .string(rendering) }
        var root: [String: CatalogJSON] = ["images": .array(entries), "info": info]
        if !properties.isEmpty { root["properties"] = .object(properties) }
        return .object(root)
    }

    /// A symbol set: one SF Symbols template.
    static func symbolSet(file: String) -> CatalogJSON {
        .object(["info": info, "symbols": .array([.object(["filename": .string(file), "idiom": .string("universal")])])])
    }

    /// A data set: one file and its uniform type.
    static func dataSet(file: String, type: String) -> CatalogJSON {
        .object(["data": .array([.object(["filename": .string(file), "idiom": .string("universal"),
                                           "universal-type-identifier": .string(type)])]), "info": info])
    }
}
