import Foundation

/// One file of a set: its path inside the set's folder and its bytes.
struct CatalogFile: Sendable, Equatable {
    var path: String
    var data: Data

    /// A `Contents.json` at `path`.
    static func contents(_ json: CatalogJSON, at path: String = "Contents.json") -> CatalogFile {
        CatalogFile(path: path, data: json.data)
    }
}
