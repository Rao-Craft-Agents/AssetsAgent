import Foundation
import UniformTypeIdentifiers

/// A data set a data line: the file, copied in, and its uniform type (`public.json` for a `.json`).
enum DataSets {
    static func make(_ spec: DataSpec, file: URL) throws -> CatalogSet {
        guard let data = try? Data(contentsOf: file) else { throw LineRefusal("data `\(spec.name)`: `\(spec.path)` cannot be read") }
        let type = UTType(filenameExtension: file.pathExtension)?.identifier ?? "public.data"
        return CatalogSet(folder: "\(spec.name).dataset", name: spec.name, files: [
            .contents(CatalogContents.dataSet(file: file.lastPathComponent, type: type)), CatalogFile(path: file.lastPathComponent, data: data),
        ])
    }
}
