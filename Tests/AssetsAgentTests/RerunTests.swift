import Foundation
import XCTest
@testable import AssetsAgent

/// Running again: a set the call makes is replaced whole, stale files and all, and every other set is left alone.
final class RerunTests: XCTestCase {
    func testASecondCallReplacesOnlyTheSetsItMakes() throws {
        let folder = try Fixture.folder()
        let catalog = folder.appendingPathComponent("Shared/Assets.xcassets")
        _ = try Fixture.write(.init(name: "Simmer", directory: folder.path))
        // The person's own set, and a stale file in one of the agent's.
        let custom = catalog.appendingPathComponent("Hero.imageset")
        try FileManager.default.createDirectory(at: custom, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: custom.appendingPathComponent("Contents.json"))
        try Data("old".utf8).write(to: catalog.appendingPathComponent("Logo.imageset/old.pdf"))
        let icon = catalog.appendingPathComponent("AppIcon.appiconset/icon-ios.png")
        let iconBefore = try Data(contentsOf: icon)

        let second = try Fixture.write(.init(name: "Simmer", shape: .leaf, sets: [.logos], directory: folder.path))
        XCTAssertEqual(second.sets, ["Logo", "LogoMark", "Wordmark", "Lockup"])
        XCTAssertFalse(second.paths.contains { $0.hasSuffix("/Contents.json") && !$0.contains(".imageset/") }, "the catalog's own Contents.json is kept, not written again")
        XCTAssertFalse(FileManager.default.fileExists(atPath: catalog.appendingPathComponent("Logo.imageset/old.pdf").path), "the set is replaced whole")
        XCTAssertTrue(FileManager.default.fileExists(atPath: custom.appendingPathComponent("Contents.json").path), "the person's set is left alone")
        XCTAssertEqual(try Data(contentsOf: icon), iconBefore, "a set the call does not make is left alone")
    }

    func testTheSameCallTwiceWritesTheSameFiles() throws {
        let folder = try Fixture.folder()
        let first = try Fixture.write(.init(name: "Simmer", sets: [.icon, .accent, .placeholders], directory: folder.path))
        let second = try Fixture.write(.init(name: "Simmer", sets: [.icon, .accent, .placeholders], directory: folder.path))
        XCTAssertEqual(Set(second.paths), Set(first.paths).subtracting([folder.appendingPathComponent("Shared/Assets.xcassets/Contents.json").path,
                                                                        folder.appendingPathComponent("Shared/Assets.xcassets/Placeholder/Contents.json").path]))
        XCTAssertTrue(first.paths.contains { $0.hasSuffix("Placeholder/Contents.json") }, "a new group's Contents.json is written once")
    }

    func testIntoAnotherCatalog() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.write(.init(into: "Watch/Assets.xcassets", name: "Simmer", sets: [.icon], platforms: [.watchos], directory: folder.path))
        XCTAssertEqual(result.catalog, folder.appendingPathComponent("Watch/Assets.xcassets").path)
        XCTAssertEqual(result.paths.map { URL(fileURLWithPath: $0).lastPathComponent }, ["Contents.json", "Contents.json", "icon-watch.png"])
    }
}
