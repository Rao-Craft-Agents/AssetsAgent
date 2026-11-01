//  WHAT: How a call's sets land in the catalog: every set staged in a catalog of its own, handed to a check
//        (actool, for each platform the call draws for), then swapped in one set at a time for the folder of the
//        same name. The catalog's `Contents.json` and a group's are written only where there are none.
//  PIN:  WHOLE OR NOTHING. A check that throws leaves the project untouched; the staging folder goes with the
//        process's temporary files.
//  PIN:  A SET IS REPLACED WHOLE, AND ONLY ITS OWN. A set this call makes takes the place of the folder of its
//        name, stale files and all; every other set in the catalog is left as it was.
//  PIN:  NEVER PRINT.

import Foundation

struct CatalogWriter {
    /// The catalog, as the host's paths name it.
    let catalog: URL

    /// Stages `sets`, hands the staged catalog to `check`, then moves each set into place. Answers the absolute
    /// paths written: a new catalog's or group's `Contents.json` first, then each set's files in order.
    func write(_ sets: [CatalogSet], check: (URL) throws -> Void) throws -> [String] {
        let manager = FileManager.default
        let stage = manager.temporaryDirectory.appendingPathComponent("assets-stage-\(UUID().uuidString.prefix(8))", isDirectory: true)
        defer { try? manager.removeItem(at: stage) }
        let staged = stage.appendingPathComponent(catalog.lastPathComponent, isDirectory: true)
        let groups = Self.groups(of: sets)

        try put(CatalogContents.catalog.data, at: staged.appendingPathComponent("Contents.json"))
        for group in groups {
            try put(CatalogContents.group(namespace: true).data, at: staged.appendingPathComponent(group).appendingPathComponent("Contents.json"))
        }
        for set in sets {
            for file in set.files {
                try put(file.data, at: staged.appendingPathComponent(set.folder).appendingPathComponent(file.path))
            }
        }
        try check(staged)

        var written: [String] = []
        try land(staged.appendingPathComponent("Contents.json"), at: catalog.appendingPathComponent("Contents.json"), into: &written)
        for group in groups {
            try land(staged.appendingPathComponent(group).appendingPathComponent("Contents.json"),
                     at: catalog.appendingPathComponent(group).appendingPathComponent("Contents.json"), into: &written)
        }
        for set in sets {
            let target = catalog.appendingPathComponent(set.folder, isDirectory: true)
            do {
                try manager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
                if manager.fileExists(atPath: target.path) { try manager.removeItem(at: target) }
                try manager.moveItem(at: staged.appendingPathComponent(set.folder, isDirectory: true), to: target)
            } catch {
                throw AgentFilesError.unwritable(target.path)
            }
            written += set.files.map { target.appendingPathComponent($0.path).path }
        }
        return written
    }

    /// The group folders the sets sit in, each once, in the order they first appear.
    static func groups(of sets: [CatalogSet]) -> [String] {
        var seen: Set<String> = [], groups: [String] = []
        for set in sets {
            guard let group = set.group else { continue }
            if seen.insert(group).inserted { groups.append(group) }
        }
        return groups
    }

    private func put(_ data: Data, at url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    /// Copies a staged `Contents.json` into the catalog when the catalog has none there.
    private func land(_ staged: URL, at target: URL, into written: inout [String]) throws {
        let manager = FileManager.default
        guard !manager.fileExists(atPath: target.path) else { return }
        do {
            try manager.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            try manager.copyItem(at: staged, to: target)
        } catch {
            throw AgentFilesError.unwritable(target.path)
        }
        written.append(target.path)
    }
}
