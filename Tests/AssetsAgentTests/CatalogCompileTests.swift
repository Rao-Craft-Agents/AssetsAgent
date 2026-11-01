import AppKit
import Foundation
import XCTest
@testable import AssetsAgent

/// The catalog as Xcode builds it: actool compiles it for iOS and macOS with no error and no warning, its
/// `Assets.car` holds every set, and what is in it loads and behaves: colours by appearance, images, the symbol
/// at every weight, the data.
final class CatalogCompileTests: XCTestCase {
    /// The asset names a recipe call writes, as code calls them.
    static let names: Set<String> = ["AppIcon", "AccentColor", "paper", "herb", "LaunchBackground", "Logo", "LogoMark", "Wordmark",
                                     "Lockup", "LaunchLogo", "Placeholder/Avatar", "Placeholder/Avatar1", "Placeholder/Avatar2",
                                     "Placeholder/Avatar3", "Placeholder/Avatar4", "Empty/Inbox", "Empty/Search", "Empty/Offline",
                                     "Empty/Error", "whisk", "timer", "pin.fill", "pantry"]

    func testTheCatalogCompilesCleanForIOSAndMacOSWithEverySet() throws {
        let folder = try Fixture.folder()
        let result = try AssetsAgent.write(try Fixture.recipes(in: folder), note: { _ in }, yield: { _ in })
        XCTAssertEqual(Set(result.sets), Self.names)
        XCTAssertFalse(result.notes.contains { $0.contains("actool") }, "the agent's own check heard no warning: \(result.notes)")
        let catalog = URL(fileURLWithPath: result.catalog)
        for platform in [AssetsPlatform.ios, .macos] {
            let compiled = try Compiled.make(catalog, platform: platform)
            XCTAssertEqual(compiled.report.errors, [], "\(platform)")
            XCTAssertEqual(compiled.report.warnings, [], "\(platform)")
            XCTAssertEqual(compiled.report.notices, [], "\(platform)")
            let names = try compiled.names()
            XCTAssertTrue(Self.names.isSubset(of: names), "\(platform) lacks \(Self.names.subtracting(names).sorted())")
        }
        let partial = try XCTUnwrap(NSDictionary(contentsOf: try Compiled.make(catalog, platform: .ios).bundle.appendingPathComponent("Contents/Resources/partial.plist")))
        XCTAssertNotNil(partial["CFBundleIcons"], "actool names the app icon for the Info.plist")
    }

    func testWhatCompiledLoadsAndBehaves() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.write(try Fixture.recipes(in: folder))
        let bundle = try Compiled.make(URL(fileURLWithPath: result.catalog), platform: .macos).load()

        // Colours resolve by appearance, exactly as the palette line said.
        let herb = try XCTUnwrap(NSColor(named: "herb", bundle: bundle))
        func hex(_ color: NSColor, _ appearance: NSAppearance.Name) -> String {
            var text = ""
            NSAppearance(named: appearance)!.performAsCurrentDrawingAppearance {
                let rgb = color.usingColorSpace(.sRGB)!
                text = SRGBColor(r: rgb.redComponent, g: rgb.greenComponent, b: rgb.blueComponent).hex
            }
            return text
        }
        XCTAssertEqual(hex(herb, .aqua), "#3A7D44")
        XCTAssertEqual(hex(herb, .darkAqua), "#7BC98A")
        XCTAssertEqual(hex(try XCTUnwrap(NSColor(named: "AccentColor", bundle: bundle)), .aqua), "#E8590C", "the accent line is the app's tint")

        // Every image loads, at the size it was drawn.
        for name in ["Logo", "LogoMark", "Wordmark", "Lockup", "LaunchLogo", "Placeholder/Avatar", "Placeholder/Avatar3", "Empty/Search"] {
            XCTAssertNotNil(bundle.image(forResource: name), name)
        }
        XCTAssertEqual(bundle.image(forResource: "Logo")?.size, NSSize(width: 128, height: 128))
        XCTAssertEqual(bundle.image(forResource: "Empty/Inbox")?.size, NSSize(width: 160, height: 160))

        // The symbols draw at every weight, heavier as the weight grows, and the filled one keeps its hole.
        for name in ["whisk", "timer", "pin.fill"] {
            let symbol = try XCTUnwrap(NSImage(symbolName: name, bundle: bundle, variableValue: 0), name)
            let inks = [NSFont.Weight.ultraLight, .regular, .black].map { Pixels.ink(symbol.withSymbolConfiguration(.init(pointSize: 64, weight: $0))!) }
            XCTAssertGreaterThan(inks[0], 50, "\(name) draws")
            if name == "pin.fill" {
                XCTAssertEqual(inks[0], inks[2], "a filled symbol is the same shape at every weight")
            } else {
                XCTAssertLessThan(inks[0], inks[1], "\(name) is heavier at regular than ultralight: \(inks)")
                XCTAssertLessThan(inks[1], inks[2], "\(name) is heavier at black than regular: \(inks)")
            }
        }
        let pin = NSImage(symbolName: "pin.fill", bundle: bundle, variableValue: 0)!.withSymbolConfiguration(.init(pointSize: 64, weight: .regular))!
        let rep = NSBitmapImageRep(data: pin.tiffRepresentation!)!
        let hole = rep.colorAt(x: rep.pixelsWide / 2, y: Int(Double(rep.pixelsHigh) * 0.36))
        XCTAssertLessThan(hole?.alphaComponent ?? 1, 0.5, "the pin's hole is a hole")

        // The data set holds the file.
        XCTAssertEqual(NSDataAsset(name: "pantry", bundle: bundle)?.data, Data(#"{"shelves": ["grains", "spices"]}"#.utf8))
    }

    func testWatchAndVisionCompileClean() throws {
        let folder = try Fixture.folder()
        let result = try Fixture.write(.init(name: "Simmer", shape: .bubble, sets: [.icon, .accent], platforms: [.ios, .macos, .watchos, .visionos], directory: folder.path))
        XCTAssertEqual(result.sets, ["AppIcon", "WatchAppIcon", "AccentColor"], "the appiconset and visionOS's layered icon are both AppIcon")
        XCTAssertTrue(result.notes.contains { $0.contains("WatchAppIcon") }, "\(result.notes)")
        let catalog = URL(fileURLWithPath: result.catalog)
        for (platform, icon) in [(AssetsPlatform.macos, "AppIcon"), (.ios, "AppIcon"), (.watchos, "WatchAppIcon"), (.visionos, "AppIcon")] {
            let compiled = try Compiled.make(catalog, platform: platform, appIcon: icon)
            XCTAssertEqual(compiled.report.errors + compiled.report.warnings, [], "\(platform)")
        }
        let vision = try Compiled.make(catalog, platform: .visionos)
        XCTAssertTrue(try vision.names().isSuperset(of: ["AppIcon/Front/Content", "AppIcon/Middle/Content", "AppIcon/Back/Content"]))
    }

    func testActoolsAnswerIsRead() {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict>
        <key>com.apple.actool.document.warnings</key><array><dict><key>affected-items</key><array><string>./AppIcon.appiconset/stray.png</string></array>
        <key>message</key><string>The app icon set "AppIcon" has an unassigned child.</string><key>type</key><string>Ambiguous Content</string></dict></array>
        <key>com.apple.actool.errors</key><array><dict><key>description</key><string>The Contents.json describing the "x.imageset" is not valid JSON.</string></dict></array>
        </dict></plist>
        """
        let report = ActoolCheck.report(from: Data(plist.utf8), status: 1)
        XCTAssertEqual(report.warnings, [#"The app icon set "AppIcon" has an unassigned child. (./AppIcon.appiconset/stray.png)"#])
        XCTAssertEqual(report.errors, [#"The Contents.json describing the "x.imageset" is not valid JSON."#])
        XCTAssertEqual(ActoolCheck.report(from: Data("not a plist".utf8), status: 2).errors.count, 1)
    }

    /// A check that refuses leaves the project as it was.
    func testACatalogTheCheckRefusesWritesNothing() throws {
        let folder = try Fixture.folder()
        let catalog = folder.appendingPathComponent("Shared/Assets.xcassets")
        let set = ColorSets.accent(light: .white, dark: .black, contrast: false)
        XCTAssertThrowsError(try CatalogWriter(catalog: catalog).write([set]) { _ in throw AssetsError.uncompiled(["no"]) })
        XCTAssertFalse(FileManager.default.fileExists(atPath: catalog.path))
    }
}
