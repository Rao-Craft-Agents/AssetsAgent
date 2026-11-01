import CoreGraphics
import Foundation
import ImageIO
import XCTest
@testable import AssetsAgent

/// What the icons are, measured: their sizes and channels as each platform requires, Apple's macOS grid, a mark
/// that still stands off its ground at 16 pixels, and the same pixels every run.
final class IconDrawTests: XCTestCase {
    private func icons(_ input: AssetsAgent.Input) throws -> [String: String] {
        let result = try Fixture.write(input)
        return Dictionary(uniqueKeysWithValues: result.paths.filter { $0.hasSuffix(".png") }.map { (URL(fileURLWithPath: $0).lastPathComponent, $0) })
    }

    func testIOSIconsAreOpaqueSquaresAndTheTintedOneIsGrey() throws {
        let files = try icons(.init(name: "Simmer", letters: "S", background: ["#F2994A", "#D9480F"], font: "Didot", sets: [.icon], directory: try Fixture.folder().path))
        for name in ["icon-ios.png", "icon-ios-dark.png", "icon-ios-tinted.png"] {
            let image = try Pixels.image(try XCTUnwrap(files[name]))
            XCTAssertEqual([image.width, image.height], [1024, 1024], name)
            XCTAssertTrue([CGImageAlphaInfo.none, .noneSkipLast, .noneSkipFirst].contains(image.alphaInfo), "\(name) has no alpha channel")
        }
        let tinted = try Pixels.image(files["icon-ios-tinted.png"]!)
        let pixels = Pixels.rgba(tinted)
        for (x, y) in [(10, 10), (512, 300), (512, 512), (700, 800), (300, 600)] {
            let color = Pixels.color(pixels, width: 1024, x, y)
            XCTAssertTrue(abs(color.red - color.green) <= 1 && abs(color.green - color.blue) <= 1, "tinted is grey at \(x),\(y): \(color)")
        }
        XCTAssertEqual(Pixels.color(pixels, width: 1024, 10, 10), SRGBColor(red: 0, green: 0, blue: 0), "on black")
    }

    func testMacIconsSitOnApplesGrid() throws {
        let files = try icons(.init(name: "Simmer", sets: [.icon], platforms: [.macos], directory: try Fixture.folder().path))
        XCTAssertEqual(files.count, 10)
        for points in IconSets.macSizes {
            for scale in [1, 2] {
                let image = try Pixels.image(try XCTUnwrap(files[scale == 1 ? "icon-mac-\(points).png" : "icon-mac-\(points)@2x.png"]))
                XCTAssertEqual(image.width, points * scale)
            }
        }
        let big = try Pixels.image(files["icon-mac-512@2x.png"]!)
        let pixels = Pixels.rgba(big)
        XCTAssertEqual(Pixels.color(pixels, width: 1024, 4, 4).alpha, 0, "the corner is clear")
        XCTAssertEqual(Pixels.color(pixels, width: 1024, 512, 60).alpha, 0, accuracy: 0.05, "nothing above the shape but its margin")
        XCTAssertEqual(Pixels.color(pixels, width: 1024, 512, 104).alpha, 1, "the shape starts 100 down")
        XCTAssertEqual(Pixels.color(pixels, width: 1024, 102, 102).alpha, 0, accuracy: 0.05, "its corner is rounded away")
        XCTAssertGreaterThan(Pixels.color(pixels, width: 1024, 512, 935).alpha, 0.05, "a shadow falls below it")
    }

    /// The mark stands off its ground at the sizes a list or the Dock shows: the lightest and darkest pixels in
    /// the middle of the shape differ by 3:1 or more.
    func testTheMarkIsLegibleAt16And32Pixels() throws {
        let calls: [AssetsAgent.Input] = [
            .init(name: "Recipe Box", sets: [.icon], platforms: [.macos]),
            .init(name: "Simmer", letters: "S", background: ["#F2994A", "#D9480F"], font: "Didot", sets: [.icon], platforms: [.macos]),
            .init(name: "Tide", shape: .wave, sets: [.icon], platforms: [.macos]),
            .init(name: "Paper", background: ["#F8F1E5", "#EADBC8"], sets: [.icon], platforms: [.macos]),
        ]
        for var call in calls {
            call.directory = try Fixture.folder().path
            let files = try icons(call)
            for (name, side) in [("icon-mac-16.png", 16), ("icon-mac-32.png", 32)] {
                let pixels = Pixels.rgba(try Pixels.image(files[name]!))
                var colors: [SRGBColor] = []
                for y in (side * 3 / 10)..<(side * 7 / 10) { for x in (side * 3 / 10)..<(side * 7 / 10) { colors.append(Pixels.color(pixels, width: side, x, y)) } }
                let light = colors.max { $0.luminance < $1.luminance }!, dark = colors.min { $0.luminance < $1.luminance }!
                XCTAssertGreaterThanOrEqual(light.contrast(with: dark), 3, "\(call.name!) at \(side) px: \(light) on \(dark)")
            }
        }
    }

    func testTheDarkIconKeepsTheBrandsHue() throws {
        let plan = try AssetsPlan.make(.init(name: "Simmer", background: ["#2F855A"], sets: [.icon], directory: try Fixture.folder().path))
        let tones = plan.brand.tones
        XCTAssertLessThan(tones.darkBackground[0].luminance, 0.06, "a dark ground")
        XCTAssertGreaterThan(tones.darkMark.oklch.c, 0.05, "the mark keeps its colour")
        XCTAssertEqual(tones.darkMark.oklch.h, SRGBColor(hex: "#2F855A")!.oklch.h, accuracy: 6, "in the brand's hue")
        XCTAssertGreaterThanOrEqual(tones.darkMark.contrast(with: tones.darkBackground[1]), 4.5)
        XCTAssertGreaterThanOrEqual(tones.accent.contrast(with: .white), 3.6, "the accent reads on white")
        XCTAssertGreaterThanOrEqual(tones.darkAccent.contrast(with: .black), 5, "and on black")
    }

    func testTheSameCallDrawsTheSamePixels() throws {
        let first = try icons(.init(name: "Braid", shape: .knot, sets: [.icon], directory: try Fixture.folder().path))
        let second = try icons(.init(name: "Braid", shape: .knot, sets: [.icon], directory: try Fixture.folder().path))
        for (name, path) in first {
            XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: path)), try Data(contentsOf: URL(fileURLWithPath: second[name]!)), name)
        }
    }

    func testEveryGlyphFitsItsBoxAndHasASmallCut() throws {
        for shape in AssetsShape.allCases {
            for small in [false, true] {
                let art = MarkArt.fitted(Glyphs.layers(shape, small: small), share: 0.5)
                XCTAssertFalse(art.layers.isEmpty, "\(shape)")
                XCTAssertEqual(max(art.bounds.width, art.bounds.height), 1, accuracy: 0.001, "\(shape) fills its box")
                XCTAssertEqual(art.bounds.midX, 0.5, accuracy: 0.001)
                XCTAssertEqual(art.bounds.midY, 0.5, accuracy: 0.001)
            }
        }
        // The knot is one strand around an open middle (its outline before fitting: the trefoil passes (0, 3)).
        let knot = Glyphs.knot(small: false)[0].path
        XCTAssertTrue(knot.contains(CGPoint(x: 0, y: 3)), "on the strand")
        XCTAssertFalse(knot.contains(.zero), "the middle of the trefoil is open")
    }

    func testAPictureIsAMarkOrAWholeIcon() throws {
        let folder = try Fixture.folder()
        let mark = folder.appendingPathComponent("mark.png"), whole = folder.appendingPathComponent("whole.png")
        let clear = Raster.image(width: 300, height: 200, opaque: false) { $0.setFillColor(SRGBColor.white.cgColor); $0.fillEllipse(in: CGRect(x: 50, y: 20, width: 200, height: 160)) }
        try Raster.png(clear).write(to: mark)
        let solid = Raster.image(width: 512, height: 512, opaque: true) { $0.setFillColor(SRGBColor(hex: "#6A2FC8")!.cgColor); $0.fill(CGRect(x: 0, y: 0, width: 512, height: 512)) }
        try Raster.png(solid).write(to: whole)
        XCTAssertFalse(try Picture.load(mark).isFullBleed)
        XCTAssertTrue(try Picture.load(whole).isFullBleed)
        let plan = try AssetsPlan.make(.init(name: "Bowl", mark: .image, image: "whole.png", sets: [.icon], directory: folder.path))
        XCTAssertEqual(plan.brand.tones.background, [SRGBColor(hex: "#6A2FC8")!, SRGBColor(hex: "#6A2FC8")!], "a whole icon is the brand's ground")
        let files = try icons(.init(name: "Bowl", mark: .image, image: "mark.png", background: ["#5C3D2E"], sets: [.icon], directory: folder.path))
        let pixels = Pixels.rgba(try Pixels.image(files["icon-ios.png"]!))
        XCTAssertEqual(Pixels.color(pixels, width: 1024, 512, 512), .white, "the picture sits in the middle")
        XCTAssertEqual(Pixels.color(pixels, width: 1024, 20, 20).hex, "#5C3D2E", "on the ground the call gave")
    }
}
