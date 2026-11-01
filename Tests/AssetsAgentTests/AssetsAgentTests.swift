import Foundation
import GraniteAgents
import XCTest
@testable import AssetsAgent

/// The package as an app finds it: by its record, with the schema a model is shown and the guide a host prompts with.
final class AssetsAgentTests: XCTestCase {
    func testTheRecordIsFoundWithNothingListed() throws {
        let assets = try XCTUnwrap(GraniteRoster.discovered().package("assets"), "the record is in this test binary")
        XCTAssertEqual(assets.module, "AssetsAgent")
        XCTAssertEqual(assets.summary, AssetsAgent.summary)
    }

    func testTheSchemaIsWhatAModelIsShown() {
        let assets = AnyAgentPackage(AssetsAgent.self)
        XCTAssertEqual(assets.schema, .object([
            .init(name: "into", schema: .string, required: false),
            .init(name: "name", schema: .string, required: false),
            .init(name: "mark", schema: .choice(["monogram", "shape", "image"]), required: false),
            .init(name: "letters", schema: .string, required: false),
            .init(name: "shape", schema: .choice(["ring", "knot", "wave", "spark", "stack", "leaf", "bubble", "grid"]), required: false),
            .init(name: "image", schema: .string, required: false),
            .init(name: "background", schema: .array(.string), required: false),
            .init(name: "foreground", schema: .string, required: false),
            .init(name: "palette", schema: .array(.string), required: false),
            .init(name: "contrast", schema: .boolean, required: false),
            .init(name: "font", schema: .string, required: false),
            .init(name: "wordmark", schema: .string, required: false),
            .init(name: "sets", schema: .array(.choice(["icon", "accent", "colors", "logos", "launch", "placeholders", "empty", "symbols", "data"])), required: false),
            .init(name: "symbols", schema: .array(.string), required: false),
            .init(name: "data", schema: .array(.string), required: false),
            .init(name: "platforms", schema: .array(.choice(["ios", "macos", "watchos", "visionos"])), required: false),
            .init(name: "directory", schema: .string, required: false),
        ]))
        XCTAssertTrue(assets.takesDirectory)
        XCTAssertEqual(Set(assets.fields.keys), ["into", "name", "mark", "letters", "shape", "image", "background", "foreground", "palette",
                                                 "contrast", "font", "wordmark", "sets", "symbols", "data", "platforms"],
                       "a note beside every field the model sees, and none for the host's folder")
        XCTAssertEqual(assets.lanes, 2)
    }

    func testTheGuideTeachesEveryModeWithACallThatDecodes() throws {
        let guide = AnyAgentPackage(AssetsAgent.self).guide
        for word in [#""letters""#, #""mark": "shape""#, #""mark": "image""#, "palette", "#light/#dark", "accent", "LaunchBackground",
                     "contrast", #""symbols""#, "0…100", ".fill", #""data""#, "sets", "platforms", "into", "SF Pro", #"Image("Logo")"#] {
            XCTAssertTrue(guide.contains(word), "the guide says \(word)")
        }
        // Every example call in the guide is one the agent's input decodes.
        var examples: [String] = [], depth = 0, current = ""
        for character in guide {
            if character == "{" { depth += 1 }
            if depth > 0 { current.append(character) }
            if character == "}" { depth -= 1; if depth == 0 { examples.append(current); current = "" } }
        }
        XCTAssertGreaterThanOrEqual(examples.count, 5, "an example call for each mode")
        for example in examples {
            XCTAssertNoThrow(try JSONDecoder().decode(AssetsAgent.Input.self, from: Data(example.utf8)), example)
        }
    }

    /// A host on the wire may give its folder only in `AgentHost`: the files land there, not in the process's folder.
    func testAHostsFolderIsUsedWhenTheCallGivesNone() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["name": "Simmer", "sets": ["icon", "accent"]])
        let answer = try await AnyAgentPackage(AssetsAgent.self).perform(input, host: AgentHost(directory: folder.path))
        let result = try JSONDecoder().decode(AssetsResult.self, from: answer)
        XCTAssertEqual(result.catalog, folder.appendingPathComponent("Shared/Assets.xcassets").path)
        XCTAssertFalse(result.paths.isEmpty)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(folder.path + "/"), path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
    }

    /// The call as a host makes it: JSON in, the host's folder filled, JSON out naming every file it wrote.
    func testACallThroughTheRosterWritesTheFilesItNames() async throws {
        let folder = try Fixture.folder()
        let input: [String: Any] = ["name": "Simmer", "letters": "S", "font": "Didot", "background": ["#F2994A", "#D9480F"],
                                    "palette": ["paper: #FFF8F0/#1C1714", "herb: #3A7D44/#7BC98A"], "directory": folder.path]
        let answer = try await AnyAgentPackage(AssetsAgent.self).perform(try JSONSerialization.data(withJSONObject: input),
                                                                         host: AgentHost(directory: folder.path, ask: "brand the recipe app"))
        let result = try JSONDecoder().decode(AssetsResult.self, from: answer)
        let catalog = folder.appendingPathComponent("Shared/Assets.xcassets")
        XCTAssertEqual(result.catalog, catalog.path)
        XCTAssertEqual(result.sets, ["AppIcon", "AccentColor", "paper", "herb", "Logo", "LogoMark", "Wordmark", "Lockup", "LaunchLogo",
                                     "Placeholder/Avatar", "Placeholder/Avatar1", "Placeholder/Avatar2", "Placeholder/Avatar3", "Placeholder/Avatar4",
                                     "Empty/Inbox", "Empty/Search", "Empty/Offline", "Empty/Error"])
        XCTAssertEqual(result.path, catalog.appendingPathComponent("AppIcon.appiconset/icon-mac-512@2x.png").path, "the largest icon first")
        let onDisk = try FileManager.default.subpathsOfDirectory(atPath: catalog.path)
            .filter { !$0.hasSuffix(".DS_Store") }
            .map { catalog.appendingPathComponent($0).path }
            .filter { var folder: ObjCBool = false; FileManager.default.fileExists(atPath: $0, isDirectory: &folder); return !folder.boolValue }
        XCTAssertEqual(Set(result.paths), Set(onDisk), "every file written is named, and nothing else")
        XCTAssertEqual(result.paths.count, 57)
        XCTAssertTrue(result.notes.contains { $0.contains("UIImageName LaunchLogo") }, "\(result.notes)")
    }
}
