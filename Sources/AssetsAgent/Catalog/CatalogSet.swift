import Foundation

/// One asset a call writes: where it sits in the catalog, the name code calls it by, and its files.
struct CatalogSet: Sendable, Equatable {
    /// The folder inside the catalog: `AppIcon.appiconset`, `Placeholder/Avatar.imageset`.
    var folder: String
    /// The name code uses: `AppIcon`, `Placeholder/Avatar`.
    var name: String
    var files: [CatalogFile]

    init(folder: String, name: String, files: [CatalogFile]) {
        self.folder = folder; self.name = name; self.files = files
    }

    /// The set's group folder inside the catalog (`Placeholder`), when it sits in one.
    var group: String? {
        let parts = folder.split(separator: "/")
        return parts.count > 1 ? parts.dropLast().joined(separator: "/") : nil
    }
}
