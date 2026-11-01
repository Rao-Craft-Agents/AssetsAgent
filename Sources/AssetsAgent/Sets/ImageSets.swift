import Foundation

/// An image set of vector PDFs: one for any appearance and one for dark when given.
enum ImageSets {
    static func vector(_ name: String, folder: String? = nil, light: Data, dark: Data?, rendering: String) -> CatalogSet {
        let base = name.split(separator: "/").last.map(String.init) ?? name
        var images: [(appearance: CatalogAppearance?, file: String)] = [(nil, "\(base).pdf")]
        var files = [CatalogFile(path: "\(base).pdf", data: light)]
        if let dark {
            images.append((.dark, "\(base)-dark.pdf"))
            files.append(CatalogFile(path: "\(base)-dark.pdf", data: dark))
        }
        return CatalogSet(folder: folder ?? "\(name).imageset", name: name,
                          files: [.contents(CatalogContents.imageSet(images, vector: true, rendering: rendering))] + files)
    }
}
