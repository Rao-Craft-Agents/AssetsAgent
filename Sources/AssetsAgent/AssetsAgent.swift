//  WHAT: An app's brand in its asset catalog, as a Granite agent package. A call gives the app's name and, as it
//        likes, a mark (letters, a geometric glyph or a picture), colours, palette lines, symbol and data lines;
//        the run draws on this Mac with CoreGraphics and CoreText (the app icon at every size and appearance, the
//        accent and palette colours, vector logos, a launch logo, placeholder avatars, empty-state illustrations,
//        custom symbols) and writes each set with the `Contents.json` Xcode would write for it.
//  IN:   Input: the catalog, the name, the mark, the colours, the palette, the font, the wordmark, the sets, the
//        symbols, the data, the platforms.
//  OUT:  AssetsResult: every file written, the catalog, the sets by the names code uses, and what the project
//        still needs.
//  PIN:  NO MODEL. The same call draws the same assets every time.
//  PIN:  THE CALL'S FOLDER, ELSE THE HOST'S. A host may give its folder only in `AgentHost`; the process's own
//        folder is the last resort, never the first.
//  PIN:  THE CATALOG COMPILES BEFORE IT LANDS. Every set is staged, compiled by actool for each platform asked
//        for, and only then swapped in, a set at a time; a refusal or a compile error writes nothing.
//  PIN:  NEVER SF PRO OR SF SYMBOLS IN AN ICON OR A LOGO. Apple's licence keeps them out; the agent draws its own
//        glyphs and sets letters only in other fonts this Mac has.

import Foundation
import GraniteAgents

public struct AssetsAgent: GraniteAgentPackage {
    public struct Input: Codable, Sendable {
        /// The asset catalog, relative to the project; `Shared/Assets.xcassets` when left out.
        public var into: String?
        /// The app's name: the monogram's initials and the wordmark.
        public var name: String?
        /// What the mark is drawn from; a monogram unless `shape` or `image` is given.
        public var mark: AssetsMark?
        /// The monogram's one to three letters; the name's initials when left out.
        public var letters: String?
        /// The glyph, when the mark is a shape.
        public var shape: AssetsShape?
        /// The picture, when the mark is an image: a PNG, JPEG, PDF or SVG in the project.
        public var image: String?
        /// The icon's background: one hex colour (solid) or two or three (a gradient, top to bottom).
        public var background: [String]?
        /// The mark's colour on the icon, hex; white or ink, by contrast, when left out.
        public var foreground: String?
        /// One colour set a line: `name: #light/#dark`.
        public var palette: [String]?
        /// Whether every colour set gets high-contrast colours.
        public var contrast: Bool?
        /// The family or face the monogram and wordmark are set in; Avenir Next when left out.
        public var font: String?
        /// The wordmark's text; the name when left out.
        public var wordmark: String?
        /// What to make; everything but symbols and data (which need their lines) when left out.
        public var sets: [AssetsSet]?
        /// One custom symbol a line: `name: SVG path data in a 0…100 box`.
        public var symbols: [String]?
        /// One data set a line: `name: path/to/file`.
        public var data: [String]?
        /// The platforms the icon is drawn for; iOS and macOS when left out.
        public var platforms: [AssetsPlatform]?
        /// The host's folder.
        public var directory: String?

        public init(into: String? = nil, name: String? = nil, mark: AssetsMark? = nil, letters: String? = nil, shape: AssetsShape? = nil,
                    image: String? = nil, background: [String]? = nil, foreground: String? = nil, palette: [String]? = nil,
                    contrast: Bool? = nil, font: String? = nil, wordmark: String? = nil, sets: [AssetsSet]? = nil, symbols: [String]? = nil,
                    data: [String]? = nil, platforms: [AssetsPlatform]? = nil, directory: String? = nil) {
            self.into = into; self.name = name; self.mark = mark; self.letters = letters; self.shape = shape; self.image = image
            self.background = background; self.foreground = foreground; self.palette = palette; self.contrast = contrast
            self.font = font; self.wordmark = wordmark; self.sets = sets; self.symbols = symbols; self.data = data
            self.platforms = platforms; self.directory = directory
        }
    }

    public typealias Event = AssetsFrame
    public typealias Output = AssetsResult
    public typealias Compute = Void

    public static let word = "assets"
    public static let summary = "draws an app's brand into its asset catalog — the app icon at every size and appearance, accent and palette colours, vector logos, a launch logo, placeholder avatars, empty-state illustrations, custom symbols and data sets — on the Mac, with no model."
    public static let fields = [
        "into": "the asset catalog, relative to the project; Shared/Assets.xcassets when left out",
        "name": "the app's name: the monogram's initials and the wordmark; the Xcode project's name when left out",
        "mark": "what the mark is: monogram (letters, the default), shape (a geometric glyph) or image (a picture in the project); a shape's own name (spark, knot, …) draws that shape",
        "letters": "the monogram's one to three letters; the name's initials when left out",
        "shape": "the glyph when mark is shape: ring, knot, wave, spark, stack, leaf, bubble or grid",
        "image": "the picture when mark is image, relative to the project: PNG, JPEG, PDF or SVG; a square opaque PNG is used as the whole icon",
        "background": "the icon's background as hex: one colour (solid) or two or three (a gradient, top to bottom); picked from the name when left out",
        "foreground": "the mark's colour on the icon as hex; white or ink, by contrast, when left out; a colour that would show under 3:1 on the background is set aside for white or ink",
        "palette": "one colour set a line, `name: #light/#dark` (one hex for both); `accent:` also sets AccentColor, `LaunchBackground:` colours the launch screen",
        "contrast": "whether every colour set also gets high-contrast colours; false when left out",
        "font": "the font family or face for the monogram and wordmark: a bundled macOS font such as Avenir Next (the default), Futura, Georgia, Didot or Menlo; never SF Pro",
        "wordmark": "the text of the wordmark and lockup; the name when left out",
        "sets": "what to make: icon, accent, colors, logos, launch, placeholders, empty, symbols, data; all but symbols and data when left out",
        "symbols": "one custom symbol a line: `name: SVG path data in a 0…100 box`, stroked at every weight; a name ending .fill is filled",
        "data": "one data set a line: `name: path/to/file` in the project",
        "platforms": "the platforms the icon is drawn for: ios, macos, watchos, visionos; ios and macos when left out",
    ]
    public static let guide = """
        Tag assets to brand an app: its icon for every platform and appearance, its accent and palette colours, its \
        logos, a launch logo, placeholder avatars, empty-state illustrations, custom symbols and data files, all \
        drawn on this Mac (no model) into the asset catalog, Shared/Assets.xcassets unless `into` names another. \
        Give the app's `name`; the mark is a monogram of its initials unless `letters`, a `shape` or an `image` says \
        otherwise. A recipe app called Simmer, its letter in Didot on a warm gradient, with two palette colours: \
        {"name": "Simmer", "letters": "S", "font": "Didot", "background": ["#F2994A", "#D9480F"], \
        "palette": ["paper: #FFF8F0/#1C1714", "herb: #3A7D44/#7BC98A"]}. A glyph instead of letters (ring, knot, \
        wave, spark, stack, leaf, bubble or grid): {"name": "Simmer", "mark": "shape", "shape": "leaf", \
        "background": ["#2F855A"]}. The project's own picture: {"name": "Simmer", "mark": "image", "image": \
        "Design/simmer-mark.svg"} (a square opaque PNG is used as the whole icon). `background` is one hex colour \
        (solid) or two or three (a gradient, top to bottom), picked from the name when left out; `foreground` \
        colours the mark, white or ink by contrast when left out. A palette line is `name: #light/#dark`, one \
        colour set each; a line named `accent` also sets AccentColor and `LaunchBackground` colours the launch \
        screen; `contrast: true` adds high-contrast colours to every set. `symbols` draws custom symbols from SVG \
        path data in a 0…100 box (y down), the path stroked at every weight, or filled when the name ends .fill: \
        {"sets": ["symbols"], "symbols": ["whisk: M30 90 L50 40 L70 90 M50 40 L50 10", \
        "timer: M50 18 A36 36 0 1 1 49.9 18 M50 34 L50 56 L64 64"]}. `data` copies a project file in as a data set: \
        {"sets": ["data"], "data": ["pantry: Resources/pantry.json"]}. `sets` picks what to make (icon, accent, \
        colors, logos, launch, placeholders, empty, symbols, data), everything but symbols and data when left out; \
        `platforms` adds watchos or visionos to ios and macos. Fonts are bundled macOS faces such as Avenir Next \
        (the default), Futura, Georgia, Didot, Gill Sans or Menlo: SF Pro and New York are refused, since their \
        licence keeps them out of icons and logos. Running again replaces only the sets it makes. Code reads them \
        as Image("Logo"), Image("LogoMark") (a template), Image("Wordmark"), Image("Lockup"), \
        Image("Placeholder/Avatar"), Image("Empty/Search"), Color("herb"), Image("whisk"), \
        NSDataAsset(name: "pantry"). A call it cannot honour is refused with every reason and nothing is written. \
        Not for UI icons that SF Symbols already has (use Image(systemName:)), nor for design tokens in code.
        """

    public static func output(from events: [AssetsFrame]) -> AssetsResult? { events.compactMap(\.result).last }

    public init() {}

    public func run(_ input: Input, context: Context) -> AsyncThrowingStream<AssetsFrame, Error> {
        // The call's folder, else the host's: a host on the wire may give it only there, and the runner's own
        // working folder is never the project.
        var resolved = input
        if resolved.directory == nil { resolved.directory = context.host.directory }
        let call = resolved
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let result = try Self.write(call, note: context.host.note) { continuation.yield($0) }
                    continuation.yield(.written(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The whole call: the input read, the assets drawn, staged, compiled and written.
    static func write(_ input: Input, check: Bool = true, note: @Sendable (String) -> Void, yield: (AssetsFrame) -> Void) throws -> AssetsResult {
        let plan = try AssetsPlan.make(input)
        yield(.planned(sets: plan.sets.count))
        let place = plan.files.relative(plan.catalog)
        note("drawing \(plan.brand.name)'s \(plan.sets.map(\.rawValue).joined(separator: ", ")) into \(place)")

        var sets: [CatalogSet] = []
        let brand = plan.brand
        if plan.sets.contains(.icon) { sets += IconSets.make(try IconPainter(brand: brand), platforms: plan.platforms) }
        if plan.sets.contains(.accent) {
            let tones = brand.tones
            sets.append(ColorSets.accent(light: plan.accent?.light ?? tones.accent, dark: plan.accent?.dark ?? tones.darkAccent, contrast: plan.contrast))
        }
        if plan.sets.contains(.colors) { sets += plan.palette.map { ColorSets.palette($0, contrast: plan.contrast) } }
        if plan.sets.contains(.logos) || plan.sets.contains(.launch) {
            let logos = try LogoPainter(brand: brand)
            if plan.sets.contains(.logos) { sets += try LogoSets.make(logos) }
            if plan.sets.contains(.launch) { sets.append(LogoSets.launch(logos)) }
        }
        if plan.sets.contains(.placeholders) { sets += try PlaceholderSets.make(AvatarPainter(brand: brand)) }
        if plan.sets.contains(.empty) { sets += EmptySets.make(EmptyPainter(brand: brand)) }
        if plan.sets.contains(.symbols) { sets += plan.symbols.map(SymbolSets.make) }
        if plan.sets.contains(.data) { sets += try plan.data.map { try DataSets.make($0.spec, file: $0.file) } }

        var warnings: [String] = []
        let written = try CatalogWriter(catalog: plan.catalog).write(sets) { staged in
            if Task.isCancelled { throw CancellationError() }
            guard check else { return }
            note("compiling the catalog with actool for \(plan.platforms.map(\.rawValue).joined(separator: ", "))")
            let icon = plan.sets.contains(.icon)
            var errors: [String] = []
            for platform in plan.platforms {
                let appIcon = icon ? (platform == .watchos && plan.platforms.contains(.macos) ? "WatchAppIcon" : "AppIcon") : nil
                let output = staged.deletingLastPathComponent().appendingPathComponent("compiled-\(platform.rawValue)")
                guard let report = try ActoolCheck.compile(staged, for: .of(platform, appIcon: appIcon), into: output) else { continue }
                errors += report.errors.map { "\(platform.rawValue): \($0)" }
                warnings += report.warnings.map { "actool warns for \(platform.rawValue): \($0)" }
            }
            if !errors.isEmpty { throw AssetsError.uncompiled(errors) }
            if Task.isCancelled { throw CancellationError() }
        }
        note("wrote \(sets.count) set\(sets.count == 1 ? "" : "s") (\(written.count) files) into \(place)")

        let launchColor = plan.palette.contains { $0.name.lowercased() == "launchbackground" }
        var notes = plan.notes + warnings + ProjectWiring.notes(root: plan.files.root, sets: plan.sets, platforms: plan.platforms, launchColor: launchColor)
        if plan.sets.contains(.icon), !Self.isWholeIcon(brand), brand.tones.markContrast < 3 {
            notes.append(String(format: "the mark's colour %@ has %.1f:1 contrast on the icon's background; 3:1 or more keeps it legible at 16 pixels",
                                brand.tones.mark.hex, brand.tones.markContrast))
        }
        let hero = written.first { $0.hasSuffix("/icon-mac-512@2x.png") } ?? written.first { $0.hasSuffix("/icon-ios.png") }
        var names: [String] = []
        for set in sets where !names.contains(set.name) { names.append(set.name) }
        return AssetsResult(path: hero ?? written.first, paths: written, catalog: plan.catalog.path, sets: names, notes: notes)
    }

    private static func isWholeIcon(_ brand: Brand) -> Bool {
        if case .image(let picture) = brand.mark { return picture.isFullBleed }
        return false
    }
}
