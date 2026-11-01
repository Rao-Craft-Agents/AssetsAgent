import Foundation
@testable import AssetsAgent

enum Fixture {
    /// A folder of its own for one test, removed with the process's temporary files.
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("assets-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A recipe app's palette: page, herb green, the accent and the launch screen's colour.
    static let palette = ["paper: #FFF8F0/#1C1714", "herb: #3A7D44/#7BC98A", "accent: #E8590C/#FF8A4C", "LaunchBackground: #FFF8F0/#1C1714"]

    /// A recipe app's symbols: two stroked, one filled with a hole.
    static let symbols = [
        "whisk: M30 90 L50 40 L70 90 M50 40 L50 10",
        "timer: M50 18 A36 36 0 1 1 49.9 18 M50 34 L50 56 L64 64",
        "pin.fill: M50 94 C50 94 18 62 18 40 A32 32 0 0 1 82 40 C82 62 50 94 50 94 Z M50 28 A12 12 0 1 0 50.01 28 Z",
    ]

    /// A recipe app's brand, the call the package is held to drawing well: every kind of set, its data file
    /// written into `folder` first.
    static func recipes(in folder: URL, platforms: [AssetsPlatform]? = nil) throws -> AssetsAgent.Input {
        let resources = folder.appendingPathComponent("Resources")
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)
        try Data(#"{"shelves": ["grains", "spices"]}"#.utf8).write(to: resources.appendingPathComponent("pantry.json"))
        return AssetsAgent.Input(name: "Simmer", letters: "S", background: ["#F2994A", "#D9480F"], palette: palette, contrast: true,
                                 font: "Didot", symbols: symbols, data: ["pantry: Resources/pantry.json"], platforms: platforms,
                                 directory: folder.path)
    }

    /// The call written without actool's check: what most tests need, in a fraction of the time.
    static func write(_ input: AssetsAgent.Input, check: Bool = false) throws -> AssetsResult {
        try AssetsAgent.write(input, check: check, note: { _ in }, yield: { _ in })
    }
}
