import Foundation

/// A minimal app project to build a catalog in: iOS and macOS app targets on one synchronized `Shared` folder, the
/// app icon and accent named, Xcode's asset symbols generated, and an iOS Info.plist whose launch screen names the
/// launch logo and colour. Its Mac app, run with `--check-assets`, prints what it found in its own bundle.
enum AppProject {
    static func write(name: String, into folder: URL) throws {
        let manager = FileManager.default
        let project = folder.appendingPathComponent("\(name).xcodeproj")
        try manager.createDirectory(at: project, withIntermediateDirectories: true)
        try pbxproj(name).write(to: project.appendingPathComponent("project.pbxproj"), atomically: true, encoding: .utf8)
        try launchPlist.write(to: folder.appendingPathComponent("iOS-Info.plist"), atomically: true, encoding: .utf8)
        let shared = folder.appendingPathComponent("Shared")
        try manager.createDirectory(at: shared, withIntermediateDirectories: true)
        try app(name).write(to: shared.appendingPathComponent("App.swift"), atomically: true, encoding: .utf8)
        try brandView.write(to: shared.appendingPathComponent("BrandView.swift"), atomically: true, encoding: .utf8)
        try check.write(to: shared.appendingPathComponent("AssetCheck.swift"), atomically: true, encoding: .utf8)
    }

    static let launchPlist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    \t<key>UILaunchScreen</key>
    \t<dict>
    \t\t<key>UIColorName</key>
    \t\t<string>LaunchBackground</string>
    \t\t<key>UIImageName</key>
    \t\t<string>LaunchLogo</string>
    \t</dict>
    </dict>
    </plist>

    """

    static func app(_ name: String) -> String {
        """
        import SwiftUI

        @main
        struct \(name)App: App {
            init() {
                #if os(macOS)
                if CommandLine.arguments.contains("--check-assets") { AssetCheck.run() }
                #endif
            }

            var body: some Scene {
                WindowGroup { BrandView() }
            }
        }

        """
    }

    /// Every kind of asset in a view, by name and by the symbols Xcode generates for the catalog.
    static let brandView = """
    import SwiftUI

    struct BrandView: View {
        var body: some View {
            VStack(spacing: 16) {
                Image("Lockup")
                HStack(spacing: 12) {
                    Image(.logo).resizable().frame(width: 64, height: 64)
                    Image("LogoMark").foregroundStyle(.tint)
                    Image("Wordmark")
                }
                HStack(spacing: 8) {
                    ForEach(["Placeholder/Avatar", "Placeholder/Avatar1", "Placeholder/Avatar2"], id: \\.self) { name in
                        Image(name).resizable().frame(width: 40, height: 40).clipShape(Circle())
                    }
                }
                Image("Empty/Search")
                Label("Whisk", image: "whisk")
                Image("timer").font(.title).fontWeight(.black)
                Text("Herbs").foregroundStyle(Color("herb"))
                Color(.paper).frame(height: 8)
            }
            .padding()
            .background(Color("paper"))
            .tint(Color.accentColor)
        }
    }

    """

    /// What the Mac app finds in its own bundle, printed as JSON, before it opens a window.
    static let check = """
    #if os(macOS)
    import AppKit

    enum AssetCheck {
        static func run() {
            var found: [String: String] = [:]
            func hex(_ name: String, _ appearance: NSAppearance.Name) -> String {
                guard let color = NSColor(named: name) else { return "missing" }
                var text = ""
                NSAppearance(named: appearance)!.performAsCurrentDrawingAppearance {
                    let rgb = color.usingColorSpace(.sRGB)!
                    text = String(format: "#%02X%02X%02X", Int((rgb.redComponent * 255).rounded()), Int((rgb.greenComponent * 255).rounded()), Int((rgb.blueComponent * 255).rounded()))
                }
                return text
            }
            found["AccentColor"] = hex("AccentColor", .aqua)
            found["herb.dark"] = hex("herb", .darkAqua)
            for name in ["Logo", "LogoMark", "Wordmark", "Lockup", "LaunchLogo", "Placeholder/Avatar", "Empty/Error"] {
                found[name] = NSImage(named: name).map { "\\(Int($0.size.width))x\\(Int($0.size.height))" } ?? "missing"
            }
            found["whisk"] = NSImage(symbolName: "whisk", bundle: .main, variableValue: 0) == nil ? "missing" : "symbol"
            found["pantry"] = NSDataAsset(name: "pantry").map { String(decoding: $0.data, as: UTF8.self) } ?? "missing"
            found["icon"] = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconName") as? String ?? "missing"
            let data = try! JSONSerialization.data(withJSONObject: found, options: [.sortedKeys])
            print(String(decoding: data, as: UTF8.self))
            exit(0)
        }
    }
    #endif

    """

    static func pbxproj(_ name: String) -> String {
        func target(_ platform: String, _ id: Int) -> String {
            """
            \t\tA5000000000000000000000\(id) /* \(name)-\(platform) */ = {
            \t\t\tisa = PBXNativeTarget;
            \t\t\tbuildConfigurationList = A6000000000000000000000\(id + 1);
            \t\t\tbuildPhases = (
            \t\t\t\tA7000000000000000000000\(id) /* Sources */,
            \t\t\t\tA3000000000000000000000\(id) /* Frameworks */,
            \t\t\t\tA8000000000000000000000\(id) /* Resources */,
            \t\t\t);
            \t\t\tbuildRules = (
            \t\t\t);
            \t\t\tdependencies = (
            \t\t\t);
            \t\t\tfileSystemSynchronizedGroups = (
            \t\t\t\tA20000000000000000000001 /* Shared */,
            \t\t\t);
            \t\t\tname = "\(name)-\(platform)";
            \t\t\tproductName = \(name);
            \t\t\tproductReference = A1000000000000000000000\(id);
            \t\t\tproductType = "com.apple.product-type.application";
            \t\t};

            """
        }
        func phases(_ id: Int) -> String {
            ["A3": "PBXFrameworksBuildPhase", "A7": "PBXSourcesBuildPhase", "A8": "PBXResourcesBuildPhase"].sorted { $0.key < $1.key }.map { prefix, isa in
                "\t\t\(prefix)000000000000000000000\(id) = {isa = \(isa); buildActionMask = 2147483647; files = (\n\t\t\t); runOnlyForDeploymentPostprocessing = 0; };\n"
            }.joined()
        }
        func settings(_ id: String, _ configuration: String, _ lines: [String]) -> String {
            "\t\t\(id) /* \(configuration) */ = {\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbuildSettings = {\n"
                + lines.map { "\t\t\t\t\($0);\n" }.joined() + "\t\t\t};\n\t\t\tname = \(configuration);\n\t\t};\n"
        }
        let common = ["ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon", "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor",
                      "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES", "CODE_SIGN_STYLE = Automatic", "CURRENT_PROJECT_VERSION = 1",
                      "GENERATE_INFOPLIST_FILE = YES", "MARKETING_VERSION = 1.0", "PRODUCT_BUNDLE_IDENTIFIER = com.example.\(name.lowercased())",
                      "PRODUCT_NAME = \(name)", "SWIFT_VERSION = 5.0"]
        let ios = common + ["INFOPLIST_FILE = \"iOS-Info.plist\"", "INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES",
                            "IPHONEOS_DEPLOYMENT_TARGET = 17.0", "SDKROOT = iphoneos", "SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\"",
                            "TARGETED_DEVICE_FAMILY = \"1,2\""]
        let mac = common + ["COMBINE_HIDPI_IMAGES = YES", "MACOSX_DEPLOYMENT_TARGET = 14.0", "SDKROOT = macosx"]
        let project = ["DEBUG_INFORMATION_FORMAT = dwarf", "ONLY_ACTIVE_ARCH = YES", "SWIFT_VERSION = 5.0"]
        return """
        // !$*UTF8*$!
        {
        \tarchiveVersion = 1;
        \tclasses = {
        \t};
        \tobjectVersion = 77;
        \tobjects = {

        /* Begin PBXFileReference section */
        \t\tA10000000000000000000001 /* \(name).app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = \(name).app; sourceTree = BUILT_PRODUCTS_DIR; };
        \t\tA10000000000000000000003 /* \(name).app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = \(name).app; sourceTree = BUILT_PRODUCTS_DIR; };
        /* End PBXFileReference section */

        /* Begin PBXFileSystemSynchronizedRootGroup section */
        \t\tA20000000000000000000001 /* Shared */ = {
        \t\t\tisa = PBXFileSystemSynchronizedRootGroup;
        \t\t\tpath = Shared;
        \t\t\tsourceTree = "<group>";
        \t\t};
        /* End PBXFileSystemSynchronizedRootGroup section */

        /* Begin build phases */
        \(phases(1))\(phases(3))/* End build phases */

        /* Begin PBXGroup section */
        \t\tA40000000000000000000001 = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\tA20000000000000000000001 /* Shared */,
        \t\t\t\tA40000000000000000000002 /* Products */,
        \t\t\t);
        \t\t\tsourceTree = "<group>";
        \t\t};
        \t\tA40000000000000000000002 /* Products */ = {
        \t\t\tisa = PBXGroup;
        \t\t\tchildren = (
        \t\t\t\tA10000000000000000000001 /* \(name).app */,
        \t\t\t\tA10000000000000000000003 /* \(name).app */,
        \t\t\t);
        \t\t\tname = Products;
        \t\t\tsourceTree = "<group>";
        \t\t};
        /* End PBXGroup section */

        /* Begin PBXNativeTarget section */
        \(target("iOS", 1))\(target("macOS", 3))/* End PBXNativeTarget section */

        /* Begin PBXProject section */
        \t\tA90000000000000000000001 /* Project object */ = {
        \t\t\tisa = PBXProject;
        \t\t\tattributes = {
        \t\t\t\tBuildIndependentTargetsInParallel = 1;
        \t\t\t\tLastSwiftUpdateCheck = 2700;
        \t\t\t\tLastUpgradeCheck = 2700;
        \t\t\t};
        \t\t\tbuildConfigurationList = A60000000000000000000001;
        \t\t\tdevelopmentRegion = en;
        \t\t\thasScannedForEncodings = 0;
        \t\t\tknownRegions = (
        \t\t\t\ten,
        \t\t\t\tBase,
        \t\t\t);
        \t\t\tmainGroup = A40000000000000000000001;
        \t\t\tminimizedProjectReferenceProxies = 1;
        \t\t\tpreferredProjectObjectVersion = 77;
        \t\t\tproductRefGroup = A40000000000000000000002 /* Products */;
        \t\t\tprojectDirPath = "";
        \t\t\tprojectRoot = "";
        \t\t\ttargets = (
        \t\t\t\tA50000000000000000000001 /* \(name)-iOS */,
        \t\t\t\tA50000000000000000000003 /* \(name)-macOS */,
        \t\t\t);
        \t\t};
        /* End PBXProject section */

        /* Begin XCBuildConfiguration section */
        \(settings("AB0000000000000000000001", "Debug", project))\(settings("AB0000000000000000000002", "Release", project))\(settings("AB0000000000000000000003", "Debug", ios))\(settings("AB0000000000000000000004", "Release", ios))\(settings("AB0000000000000000000005", "Debug", mac))\(settings("AB0000000000000000000006", "Release", mac))/* End XCBuildConfiguration section */

        /* Begin XCConfigurationList section */
        \t\tA60000000000000000000001 = {isa = XCConfigurationList; buildConfigurations = (AB0000000000000000000001, AB0000000000000000000002, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
        \t\tA60000000000000000000002 = {isa = XCConfigurationList; buildConfigurations = (AB0000000000000000000003, AB0000000000000000000004, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
        \t\tA60000000000000000000004 = {isa = XCConfigurationList; buildConfigurations = (AB0000000000000000000005, AB0000000000000000000006, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
        /* End XCConfigurationList section */
        \t};
        \trootObject = A90000000000000000000001 /* Project object */;
        }

        """
    }
}
