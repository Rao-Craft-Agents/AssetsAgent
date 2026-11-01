import AppKit
import Foundation
import XCTest
@testable import AssetsAgent

/// A catalog compiled by actool into a bundle a test can load, and what is in its `Assets.car`.
struct Compiled {
    let report: ActoolReport
    let bundle: URL

    /// Compiles `catalog` for `platform` into a fresh bundle, its app icon `appIcon`.
    static func make(_ catalog: URL, platform: AssetsPlatform, appIcon: String? = "AppIcon") throws -> Compiled {
        let bundle = try Fixture.folder().appendingPathComponent("Compiled.bundle", isDirectory: true)
        let resources = bundle.appendingPathComponent("Contents/Resources", isDirectory: true)
        let report = try XCTUnwrap(try ActoolCheck.compile(catalog, for: .of(platform, appIcon: appIcon), into: resources), "actool is installed")
        try """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict><key>CFBundleIdentifier</key><string>test.assets.\(UUID().uuidString.prefix(8))</string><key>CFBundlePackageType</key><string>BNDL</string></dict></plist>
        """.write(to: bundle.appendingPathComponent("Contents/Info.plist"), atomically: true, encoding: .utf8)
        return Compiled(report: report, bundle: bundle)
    }

    var car: URL { bundle.appendingPathComponent("Contents/Resources/Assets.car") }

    /// Every asset name in the compiled catalog, as `assetutil --info` lists them.
    func names() throws -> Set<String> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["assetutil", "--info", car.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let entries = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        return Set(entries.compactMap { $0["Name"] as? String })
    }

    /// The compiled bundle, loaded.
    func load() throws -> Bundle { try XCTUnwrap(Bundle(path: bundle.path)) }
}

/// Measuring what was drawn.
enum Pixels {
    /// The image at `path`, decoded.
    static func image(_ path: String) throws -> CGImage {
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil))
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    /// Every pixel of `image` as 8-bit RGBA, rows from the top.
    static func rgba(_ image: CGImage) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = CGContext(data: &pixels, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return pixels
    }

    /// The colour at (x, y), y from the top.
    static func color(_ pixels: [UInt8], width: Int, _ x: Int, _ y: Int) -> SRGBColor {
        let i = (y * width + x) * 4
        return SRGBColor(red: Int(pixels[i]), green: Int(pixels[i + 1]), blue: Int(pixels[i + 2]), alpha: Double(pixels[i + 3]) / 255)
    }

    /// How many opaque pixels `image` drawn into a `side`-point square has: ink, for a symbol.
    static func ink(_ image: NSImage, side: Int = 128) -> Int {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        NSGraphicsContext.restoreGraphicsState()
        var count = 0
        for y in 0..<side { for x in 0..<side where (rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5 { count += 1 } }
        return count
    }
}
