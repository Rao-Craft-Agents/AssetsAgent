import CoreGraphics
import Foundation
import XCTest
@testable import AssetsAgent

/// The lines a model writes, read: every form the guide promises, and a reason for every one refused.
final class LineTests: XCTestCase {
    func testHexColours() {
        XCTAssertEqual(SRGBColor(hex: "#A19A8E"), SRGBColor(red: 0xA1, green: 0x9A, blue: 0x8E))
        XCTAssertEqual(SRGBColor(hex: "a19a8e"), SRGBColor(red: 0xA1, green: 0x9A, blue: 0x8E))
        XCTAssertEqual(SRGBColor(hex: "0xA19A8E"), SRGBColor(red: 0xA1, green: 0x9A, blue: 0x8E))
        XCTAssertEqual(SRGBColor(hex: "#FA0"), SRGBColor(red: 0xFF, green: 0xAA, blue: 0x00))
        XCTAssertEqual(SRGBColor(hex: "#00000080")?.alpha ?? 0, 128.0 / 255, accuracy: 0.001)
        for bad in ["#12", "#GGGGGG", "blue", "#1234567"] { XCTAssertNil(SRGBColor(hex: bad), bad) }
        XCTAssertEqual(SRGBColor(hex: "#A19A8E")!.hex, "#A19A8E")
    }

    func testPaletteLines() throws {
        let both = try PaletteLine.parse("brand: #A19A8E/#CFCAC1")
        XCTAssertEqual(both.name, "brand")
        XCTAssertEqual(both.light, SRGBColor(hex: "#A19A8E"))
        XCTAssertEqual(both.dark, SRGBColor(hex: "#CFCAC1"))
        XCTAssertNil(try PaletteLine.parse("ink: #1D1B19").dark, "one hex is the same in both")
        XCTAssertEqual(try PaletteLine.parse("surface = #FFFFFF / #121212").dark, SRGBColor(hex: "#121212"))
        let four = try PaletteLine.parse("danger: #D93A2B/#FF6B5E/#A3180D/#FFA39A")
        XCTAssertEqual(four.darkHigh, SRGBColor(hex: "#FFA39A"))
        let refused: [(String, String)] = [
            ("brand #A19A8E/#CFCAC1/#000", "gives 3 colours"),
            ("brand: blue", "not a hex colour"),
            ("1brand: #FFFFFF", "not a colour name"),
            ("brand:", "is not `name: #light/#dark`"),
        ]
        for (line, reason) in refused {
            XCTAssertThrowsError(try PaletteLine.parse(line), line) { XCTAssertTrue("\($0)".contains(reason), "\(line) → \($0)") }
        }
    }

    func testSymbolAndDataLines() throws {
        let whisk = try SymbolLine.parse("whisk: M30 90 L50 40 L70 90 M50 40 L50 10")
        XCTAssertEqual(whisk.name, "whisk")
        XCTAssertFalse(whisk.filled)
        XCTAssertEqual(whisk.path.subpaths.count, 2)
        XCTAssertTrue(try SymbolLine.parse("pin.fill: M50 90 L20 40 L80 40 Z").filled)
        let named = try SymbolLine.parse("badge fill: M50 90 L20 40 L80 40 Z")
        XCTAssertEqual(named.name, "badge")
        XCTAssertTrue(named.filled)
        for (line, reason) in [("far: M10 10 L130 50", "outside its 0…100 box"), ("odd: M10 10 X 4", "not an SVG path command"),
                               ("lost: 10 10 L 20 20", "must start with M"), ("bad name!: M0 0 L1 1", "not a symbol name")] {
            XCTAssertThrowsError(try SymbolLine.parse(line), line) { XCTAssertTrue("\($0)".contains(reason), "\(line) → \($0)") }
        }
        let data = try DataLine.parse("pantry: Resources/pantry.json")
        XCTAssertEqual(data, DataSpec(name: "pantry", path: "Resources/pantry.json"))
        XCTAssertThrowsError(try DataLine.parse("pantry"))
    }

    func testSVGPathData() throws {
        // Relative commands, implicit line-tos after a move, numbers run together, H and V.
        let path = try SVGPath.parse("m10 10 20 0v20h-20z M-.5.5")
        XCTAssertEqual(path.subpaths[0].segments.map(\.end), [CGPoint(x: 30, y: 10), CGPoint(x: 30, y: 30), CGPoint(x: 10, y: 30)])
        XCTAssertTrue(path.subpaths[0].closed)
        // A half circle by an arc ends where it says, its bulge to the right side.
        let arc = try SVGPath.parse("M50 10 A40 40 0 0 1 50 90")
        XCTAssertEqual(arc.subpaths[0].segments.last?.end, CGPoint(x: 50, y: 90))
        XCTAssertEqual(arc.bounds.maxX, 90, accuracy: 0.5)
        // Quadratic curves and their reflections become cubics through the same points.
        let quad = try SVGPath.parse("M0 50 Q25 0 50 50 T100 50")
        XCTAssertEqual(quad.subpaths[0].segments.count, 2)
        XCTAssertEqual(quad.bounds.minY, 25, accuracy: 0.5)
        XCTAssertEqual(quad.bounds.maxY, 75, accuracy: 0.5)
        // Points along a curve depend on the path alone.
        XCTAssertEqual(arc.polylines()[0].points.count, try SVGPath.parse("M50 10 A40 40 0 0 1 50 90").polylines()[0].points.count)
    }

    func testFonts() throws {
        let avenir = try FontChoice.resolve(nil)
        XCTAssertEqual(avenir.monogram, "AvenirNext-Bold")
        XCTAssertEqual(avenir.wordmark, "AvenirNext-DemiBold")
        XCTAssertEqual(try FontChoice.resolve("Futura").monogram, "Futura-Bold")
        XCTAssertEqual(try FontChoice.resolve("Futura Bold"), FontChoice(monogram: "Futura-Bold", wordmark: "Futura-Bold"))
        XCTAssertEqual(try FontChoice.resolve("Georgia-Italic"), FontChoice(monogram: "Georgia-Italic", wordmark: "Georgia-Italic"))
        for name in ["SF Pro", "SF Pro Rounded", "SFPro-Bold", "New York", "SF Mono", ".SFNS-Regular", "System Font"] {
            XCTAssertThrowsError(try FontChoice.resolve(name), name) { XCTAssertTrue("\($0)".contains("licence"), "\(name) → \($0)") }
        }
        XCTAssertThrowsError(try FontChoice.resolve("Comic Neue Fancy")) { XCTAssertTrue("\($0)".contains("no font called")) }
    }

    /// A letter the face lacks is never set in another font behind the call's back: it is refused, naming fonts that have it.
    func testALetterTheFontLacksIsRefusedNamingFontsThatHaveIt() throws {
        let folder = try Fixture.folder().path
        XCTAssertThrowsError(try AssetsPlan.make(.init(name: "Loom", letters: "ℓ", font: "Didot", directory: folder))) { error in
            XCTAssertTrue("\(error)".contains("Didot does not"), "\(error)")
            XCTAssertTrue("\(error)".contains("Georgia"), "names a font that has it: \(error)")
        }
        XCTAssertEqual(try AssetsPlan.make(.init(name: "Loom", letters: "ℓ", font: "Georgia", directory: folder)).brand.mark, .monogram("ℓ"))
        XCTAssertThrowsError(try AssetsPlan.make(.init(name: "Loom", font: "Didot", wordmark: "Loom ℓ", directory: folder))) { error in
            XCTAssertTrue("\(error)".contains("Didot does not"), "the wordmark too: \(error)")
        }
    }

    func testInitialsAndTheAppsName() throws {
        XCTAssertEqual(AssetsPlan.initials("Simmer"), "S")
        XCTAssertEqual(AssetsPlan.initials("Recipe Box"), "RB")
        XCTAssertEqual(AssetsPlan.initials("cook-book club"), "CB")
        let folder = try Fixture.folder()
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("Larder.xcodeproj"), withIntermediateDirectories: true)
        XCTAssertEqual(AssetsPlan.projectName(folder), "Larder", "the Xcode project names the app")
    }

    func testTheMarkFollowsWhatTheCallGives() throws {
        let folder = try Fixture.folder().path
        XCTAssertEqual(try AssetsPlan.make(.init(name: "Simmer", directory: folder)).brand.mark, .monogram("S"))
        XCTAssertEqual(try AssetsPlan.make(.init(name: "Simmer", shape: .wave, directory: folder)).brand.mark, .shape(.wave))
        XCTAssertEqual(try AssetsPlan.make(.init(name: "Simmer", letters: "sm", directory: folder)).brand.mark, .monogram("sm"), "letters as given")
        let plan = try AssetsPlan.make(.init(name: "Simmer", palette: Fixture.palette, directory: folder))
        XCTAssertEqual(plan.sets, [.icon, .accent, .colors, .logos, .launch, .placeholders, .empty], "everything but symbols and data")
        XCTAssertEqual(plan.accent?.light, SRGBColor(hex: "#E8590C"), "the accent line is the accent")
        XCTAssertEqual(plan.palette.map(\.name), ["paper", "herb", "LaunchBackground"], "the accent line is AccentColor, not a set of its own")
        XCTAssertEqual(plan.catalog.path, folder + "/Shared/Assets.xcassets")
        XCTAssertEqual(try AssetsPlan.make(.init(into: "App/Resources", directory: folder)).catalog.path, folder + "/App/Resources/Assets.xcassets")
    }

    /// A call it cannot honour names every problem at once, and nothing is written.
    func testARefusedCallNamesEveryReasonAndWritesNothing() throws {
        let folder = try Fixture.folder()
        let input = AssetsAgent.Input(letters: "ABCD", background: ["#12", "#FFFFFF", "#000000", "#EEEEEE"], foreground: "white",
                                      palette: ["paper: #FFFFFF", "paperColor: #FFFFFF", "brand: nope"], font: "SF Pro", sets: [.colors, .symbols],
                                      symbols: ["far: M0 0 L200 200", "logo: M0 0 L10 10", "pin.fill: M0 0 L10 10 L0 10 Z", "pinFill: M0 0 L10 10 L0 10 Z"],
                                      data: ["pantry: Resources/missing.json"], directory: folder.path)
        XCTAssertThrowsError(try Fixture.write(input)) { error in
            guard case .refused(let reasons)? = error as? AssetsError else { return XCTFail("\(error)") }
            for reason in ["`paper` and `paperColor`, which Xcode's asset symbols both call `paper`", "takes the name of an image the agent draws",
                           "`pin.fill` and `pinFill`", "`nope` is not a hex colour", "outside its 0…100 box",
                           "no file at `Resources/missing.json`", "licence", "background `#12`",
                           "gives 4 colours", "foreground `white`", "4 characters"] {
                XCTAssertTrue(reasons.contains { $0.contains(reason) }, "says \(reason): \(reasons)")
            }
            XCTAssertTrue("\(error)".hasPrefix("\(reasons.count) parts of the call cannot be honoured"), "\(error)")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appendingPathComponent("Shared").path), "nothing written")
        XCTAssertThrowsError(try Fixture.write(.init(mark: .image, directory: folder.path))) { XCTAssertTrue("\($0)".contains("`image` names no file")) }
        XCTAssertThrowsError(try Fixture.write(.init(mark: .shape, directory: folder.path))) { XCTAssertTrue("\($0)".contains("`shape` names no glyph")) }
        XCTAssertThrowsError(try Fixture.write(.init(sets: [.symbols], directory: folder.path))) { XCTAssertTrue("\($0)".contains("`symbols` gives no lines")) }
        XCTAssertThrowsError(try Fixture.write(.init(sets: [.colors], directory: folder.path))) { XCTAssertTrue("\($0)".contains("`palette` gives no lines")) }
    }
}

/// What a local model writes when it names the glyph where the kind goes, and a mark colour that does not show.
final class MarkReadingTests: XCTestCase {
    func testAShapesNameWhereTheMarkGoesDrawsThatShape() throws {
        let folder = try Fixture.folder().path
        let plan = try AssetsPlan.make(.init(name: "Hearth", mark: .spark, directory: folder))
        XCTAssertEqual(plan.brand.mark, .shape(.spark))
    }

    func testAMarkColourUnderThreeToOneIsSetAsideAndSaid() throws {
        let folder = try Fixture.folder().path
        let plan = try AssetsPlan.make(.init(name: "Hearth", mark: .shape, shape: .spark, background: ["#FF7A50", "#B8361A"],
                                             foreground: "#E4572E", directory: folder))
        XCTAssertNotEqual(plan.brand.tones.mark, SRGBColor(hex: "#E4572E"), "an ember mark on an ember ground does not show")
        XCTAssertGreaterThanOrEqual(plan.brand.tones.mark.contrast(with: BrandTones.middle(of: plan.brand.tones.background)), 3)
        XCTAssertTrue(plan.notes.contains { $0.contains("under the 3:1 a mark needs") }, "\(plan.notes)")
        let kept = try AssetsPlan.make(.init(name: "Hearth", mark: .shape, shape: .spark, background: ["#FF7A50", "#B8361A"],
                                             foreground: "#FFFFFF", directory: folder))
        XCTAssertEqual(kept.brand.tones.mark, SRGBColor(hex: "#FFFFFF"), "a colour that reads is kept")
    }
}
