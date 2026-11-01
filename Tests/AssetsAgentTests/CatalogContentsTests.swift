import Foundation
import XCTest
@testable import AssetsAgent

/// The `Contents.json` of every kind of set, byte for byte as Xcode writes it: files Xcode wrote read and written
/// back unchanged, and each builder's text pinned.
final class CatalogContentsTests: XCTestCase {
    /// Files Xcode wrote: a colour set (Loom), a group with a namespace (Loom), a template image set (Loom), and the
    /// iOS app icon in three appearances (Xcode 27's own project template).
    static let xcodeWritten = [
        """
        {
          "colors" : [
            {
              "color" : {
                "color-space" : "srgb",
                "components" : {
                  "alpha" : "1.000",
                  "blue" : "0xFF",
                  "green" : "0xFF",
                  "red" : "0xFF"
                }
              },
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                }
              ],
              "color" : {
                "color-space" : "srgb",
                "components" : {
                  "alpha" : "1.000",
                  "blue" : "18",
                  "green" : "18",
                  "red" : "18"
                }
              },
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """,
        """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          },
          "properties" : {
            "provides-namespace" : true
          }
        }
        """,
        """
        {
          "images" : [
            {
              "filename" : "floor_icon.pdf",
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          },
          "properties" : {
            "compression-type" : "lossless",
            "preserves-vector-representation" : true,
            "template-rendering-intent" : "template"
          }
        }
        """,
        """
        {
          "images" : [
            {
              "idiom" : "universal",
              "platform" : "ios",
              "size" : "1024x1024"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                }
              ],
              "idiom" : "universal",
              "platform" : "ios",
              "size" : "1024x1024"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "tinted"
                }
              ],
              "idiom" : "universal",
              "platform" : "ios",
              "size" : "1024x1024"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """,
    ].map { $0 + "\n" }

    func testFilesXcodeWroteAreWrittenBackByteForByte() throws {
        for text in Self.xcodeWritten {
            let json = try Self.json(JSONSerialization.jsonObject(with: Data(text.utf8)))
            XCTAssertEqual(json.text, text)
        }
    }

    func testTheIOSIconIsTheShapeXcode27Writes() throws {
        let ours = CatalogContents.appIcon(ios: [(nil, "a.png"), (.dark, "b.png"), (.tinted, "c.png")], mac: [], watch: nil)
        XCTAssertEqual(Self.stripped(ours, "filename").text, Self.xcodeWritten[3], "the same entries in the same order, with filenames added")
    }

    func testTheCatalogAndAGroup() {
        XCTAssertEqual(CatalogContents.catalog.text, "{\n  \"info\" : {\n    \"author\" : \"xcode\",\n    \"version\" : 1\n  }\n}\n")
        XCTAssertEqual(CatalogContents.group(namespace: true).text, Self.xcodeWritten[1])
    }

    func testTheAppIconForIOSAndMacOS() throws {
        let set = try XCTUnwrap(Self.drawnSets(sets: [.icon]).first { $0.folder == "AppIcon.appiconset" })
        let text = String(decoding: set.files[0].data, as: UTF8.self)
        var expected = """
        {
          "images" : [
            {
              "filename" : "icon-ios.png",
              "idiom" : "universal",
              "platform" : "ios",
              "size" : "1024x1024"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                }
              ],
              "filename" : "icon-ios-dark.png",
              "idiom" : "universal",
              "platform" : "ios",
              "size" : "1024x1024"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "tinted"
                }
              ],
              "filename" : "icon-ios-tinted.png",
              "idiom" : "universal",
              "platform" : "ios",
              "size" : "1024x1024"
            },
        """
        for points in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                expected += """

                    {
                      "filename" : "icon-mac-\(points)\(scale == 2 ? "@2x" : "").png",
                      "idiom" : "mac",
                      "scale" : "\(scale)x",
                      "size" : "\(points)x\(points)"
                    },
                """
            }
        }
        expected.removeLast()
        expected += """

          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }

        """
        XCTAssertEqual(text, expected)
        XCTAssertEqual(set.files.map(\.path).sorted(), (["Contents.json", "icon-ios.png", "icon-ios-dark.png", "icon-ios-tinted.png"]
            + [16, 32, 128, 256, 512].flatMap { ["icon-mac-\($0).png", "icon-mac-\($0)@2x.png"] }).sorted())
    }

    func testAColourSetWithDarkAndHighContrast() throws {
        let color = try PaletteLine.parse("danger: #D93A2B/#FF6B5E/#A3180D/#FFA39A")
        let text = String(decoding: ColorSets.palette(color, contrast: false).files[0].data, as: UTF8.self)
        func entry(_ appearances: [(String, String)], _ r: String, _ g: String, _ b: String) -> String {
            var lines = ["    {"]
            if !appearances.isEmpty {
                lines.append("      \"appearances\" : [")
                lines.append(appearances.map { "        {\n          \"appearance\" : \"\($0.0)\",\n          \"value\" : \"\($0.1)\"\n        }" }.joined(separator: ",\n"))
                lines.append("      ],")
            }
            lines += ["      \"color\" : {", "        \"color-space\" : \"srgb\",", "        \"components\" : {", "          \"alpha\" : \"1.000\",",
                      "          \"blue\" : \"\(b)\",", "          \"green\" : \"\(g)\",", "          \"red\" : \"\(r)\"", "        }", "      },",
                      "      \"idiom\" : \"universal\"", "    }"]
            return lines.joined(separator: "\n")
        }
        let expected = "{\n  \"colors\" : [\n" + [
            entry([], "0xD9", "0x3A", "0x2B"),
            entry([("luminosity", "dark")], "0xFF", "0x6B", "0x5E"),
            entry([("contrast", "high")], "0xA3", "0x18", "0x0D"),
            entry([("luminosity", "dark"), ("contrast", "high")], "0xFF", "0xA3", "0x9A"),
        ].joined(separator: ",\n") + "\n  ],\n  \"info\" : {\n    \"author\" : \"xcode\",\n    \"version\" : 1\n  }\n}\n"
        XCTAssertEqual(text, expected)
    }

    func testAColourWithOneHexHasNoDarkEntryAndContrastDerivesHighContrast() throws {
        let plain = try Self.json(JSONSerialization.jsonObject(with: ColorSets.palette(try PaletteLine.parse("ink: #1D1B19"), contrast: false).files[0].data))
        XCTAssertEqual(Self.count(plain, "colors"), 1)
        let both = ColorSets.accent(light: SRGBColor(hex: "#E8590C")!, dark: SRGBColor(hex: "#FF8A4C")!, contrast: true)
        XCTAssertEqual(both.folder, "AccentColor.colorset")
        let json = try Self.json(JSONSerialization.jsonObject(with: both.files[0].data))
        XCTAssertEqual(Self.count(json, "colors"), 4)
        let lightHigh = ColorSets.highContrast(SRGBColor(hex: "#E8590C")!, dark: false), darkHigh = ColorSets.highContrast(SRGBColor(hex: "#FF8A4C")!, dark: true)
        XCTAssertGreaterThan(lightHigh.contrast(with: .white), SRGBColor(hex: "#E8590C")!.contrast(with: .white), "darker on a light page")
        XCTAssertGreaterThan(darkHigh.contrast(with: .black), SRGBColor(hex: "#FF8A4C")!.contrast(with: .black), "lighter on a dark page")
        XCTAssertEqual(ColorSets.highContrast(.white, dark: false), .white, "a page stays a page, only further out")
    }

    func testVectorImageSets() {
        let logo = ImageSets.vector("Logo", light: Data(), dark: Data(), rendering: "original")
        XCTAssertEqual(String(decoding: logo.files[0].data, as: UTF8.self), """
        {
          "images" : [
            {
              "filename" : "Logo.pdf",
              "idiom" : "universal"
            },
            {
              "appearances" : [
                {
                  "appearance" : "luminosity",
                  "value" : "dark"
                }
              ],
              "filename" : "Logo-dark.pdf",
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          },
          "properties" : {
            "preserves-vector-representation" : true,
            "template-rendering-intent" : "original"
          }
        }

        """)
        let mark = ImageSets.vector("LogoMark", light: Data(), dark: nil, rendering: "template")
        XCTAssertTrue(String(decoding: mark.files[0].data, as: UTF8.self).contains("\"template-rendering-intent\" : \"template\""))
        let avatar = ImageSets.vector("Placeholder/Avatar", light: Data(), dark: nil, rendering: "original")
        XCTAssertEqual(avatar.folder, "Placeholder/Avatar.imageset")
        XCTAssertEqual(avatar.group, "Placeholder")
        XCTAssertEqual(avatar.files.map(\.path), ["Contents.json", "Avatar.pdf"])
    }

    func testSymbolDataAndLayeredIconSets() throws {
        XCTAssertEqual(CatalogContents.symbolSet(file: "whisk.svg").text, """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          },
          "symbols" : [
            {
              "filename" : "whisk.svg",
              "idiom" : "universal"
            }
          ]
        }

        """)
        XCTAssertEqual(CatalogContents.dataSet(file: "pantry.json", type: "public.json").text, """
        {
          "data" : [
            {
              "filename" : "pantry.json",
              "idiom" : "universal",
              "universal-type-identifier" : "public.json"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }

        """)
        XCTAssertEqual(CatalogContents.solidImageStack(layers: ["Front", "Middle", "Back"]).text, """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          },
          "layers" : [
            {
              "filename" : "Front.solidimagestacklayer"
            },
            {
              "filename" : "Middle.solidimagestacklayer"
            },
            {
              "filename" : "Back.solidimagestacklayer"
            }
          ]
        }

        """)
        XCTAssertEqual(CatalogContents.stackLayerContent(file: "front.png").text, """
        {
          "images" : [
            {
              "filename" : "front.png",
              "idiom" : "vision",
              "scale" : "2x"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }

        """)
        let vision = try XCTUnwrap(Self.drawnSets(sets: [.icon], platforms: [.visionos]).first)
        XCTAssertEqual(vision.folder, "AppIcon.solidimagestack")
        XCTAssertEqual(vision.files.map(\.path), ["Contents.json",
            "Front.solidimagestacklayer/Contents.json", "Front.solidimagestacklayer/Content.imageset/Contents.json", "Front.solidimagestacklayer/Content.imageset/front.png",
            "Middle.solidimagestacklayer/Contents.json", "Middle.solidimagestacklayer/Content.imageset/Contents.json", "Middle.solidimagestacklayer/Content.imageset/middle.png",
            "Back.solidimagestacklayer/Contents.json", "Back.solidimagestacklayer/Content.imageset/Contents.json", "Back.solidimagestacklayer/Content.imageset/back.png"])
    }

    func testAWatchIconSharesTheSetUnlessTheSetHasMacSizes() throws {
        let watchAndPhone = try Self.drawnSets(sets: [.icon], platforms: [.ios, .watchos])
        XCTAssertEqual(watchAndPhone.map(\.folder), ["AppIcon.appiconset"])
        XCTAssertTrue(String(decoding: watchAndPhone[0].files[0].data, as: UTF8.self).contains("\"platform\" : \"watchos\""))
        let watchAndMac = try Self.drawnSets(sets: [.icon], platforms: [.macos, .watchos])
        XCTAssertEqual(watchAndMac.map(\.folder), ["AppIcon.appiconset", "WatchAppIcon.appiconset"])
        XCTAssertFalse(String(decoding: watchAndMac[0].files[0].data, as: UTF8.self).contains("watchos"))
    }

    // MARK: - Helpers

    /// The icon sets a recipe call draws, without writing them.
    static func drawnSets(sets: [AssetsSet], platforms: [AssetsPlatform] = [.ios, .macos]) throws -> [CatalogSet] {
        let plan = try AssetsPlan.make(AssetsAgent.Input(name: "Simmer", sets: sets, platforms: platforms, directory: try Fixture.folder().path))
        return IconSets.make(try IconPainter(brand: plan.brand), platforms: plan.platforms)
    }

    /// A value `JSONSerialization` read, as the catalog's JSON (a `true` stays a boolean).
    static func json(_ value: Any) throws -> CatalogJSON {
        switch value {
        case let text as String: return .string(text)
        case let number as NSNumber:
            return CFGetTypeID(number) == CFBooleanGetTypeID() ? .bool(number.boolValue) : .int(number.intValue)
        case let items as [Any]: return .array(try items.map(json))
        case let fields as [String: Any]: return .object(try fields.mapValues(json))
        default: throw NSError(domain: "json", code: 1)
        }
    }

    static func stripped(_ value: CatalogJSON, _ key: String) -> CatalogJSON {
        switch value {
        case .array(let items): return .array(items.map { stripped($0, key) })
        case .object(let fields): return .object(fields.filter { $0.key != key }.mapValues { stripped($0, key) })
        default: return value
        }
    }

    static func count(_ value: CatalogJSON, _ key: String) -> Int {
        if case .object(let fields) = value, case .array(let items)? = fields[key] { return items.count }
        return -1
    }
}
