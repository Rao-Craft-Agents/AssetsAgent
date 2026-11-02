//  WHAT: A call read into what it makes: the catalog, the sets, the platforms, the brand (name, mark, faces,
//        colours), the palette, the symbols and the data, every value checked.
//  PIN:  EVERY PROBLEM AT ONCE. Each value that cannot be honoured adds its sentence and the reading goes on, so
//        one refusal names everything to fix; a call is refused before anything is drawn or written.
//  PIN:  ONE NAME, ONE SYMBOL. Xcode turns every asset's name into a Swift symbol (`Color(.herb)`, `Image(.logo)`),
//        dropping a colour's `Color` and every mark that is not a letter or a digit; two names that come out the
//        same make the app's build warn, so they are refused, and a palette line named `accent` is the
//        AccentColor itself.

import Foundation

struct AssetsPlan: Sendable {
    var files: AgentFiles
    var catalog: URL
    var sets: [AssetsSet]
    var platforms: [AssetsPlatform]
    var brand: Brand
    var contrast: Bool
    var accent: PaletteColor?
    var palette: [PaletteColor]
    var symbols: [SymbolSpec]
    var data: [(spec: DataSpec, file: URL)]
    var notes: [String]

    /// The symbols of the images the agent draws itself, which a symbol line may not take.
    static let drawn: Set<String> = ["appicon", "watchappicon", "logo", "logomark", "wordmark", "lockup", "launchlogo"]

    /// The Swift symbol Xcode generates for an asset, compared without case: its letters and digits, a colour's
    /// trailing `Color` dropped (`AccentColor` is `accent`, `pin.fill` is `pinfill`).
    static func symbolKey(_ name: String, color: Bool) -> String {
        var key = name.lowercased().filter { $0.isLetter || $0.isNumber }
        if color, key.hasSuffix("color"), key.count > 5 { key.removeLast(5) }
        return key
    }

    static func make(_ input: AssetsAgent.Input) throws -> AssetsPlan {
        var reasons: [String] = [], notes: [String] = []
        let files = AgentFiles(directory: input.directory)

        // Where: the catalog, `into` or the app's shared one.
        var into = (input.into ?? "").trimmingCharacters(in: .whitespaces)
        while into.hasSuffix("/") { into.removeLast() }
        if into.isEmpty { into = "Shared/Assets.xcassets" } else if !into.hasSuffix(".xcassets") { into += "/Assets.xcassets" }
        let catalog = files.resolve(into)

        let platforms = unique(input.platforms ?? [.ios, .macos])
        if platforms.isEmpty { reasons.append("`platforms` names none: give ios, macos, watchos or visionos, or leave it out for ios and macos") }

        // The lines.
        var palette: [PaletteColor] = [], accent: PaletteColor?
        var named: [String: String] = [:]
        for line in (input.palette ?? []).filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            do {
                let color = try PaletteLine.parse(line)
                let key = symbolKey(color.name, color: true)
                if let other = named[key] {
                    reasons.append(other == color.name ? "palette names `\(color.name)` twice"
                                   : "palette names `\(other)` and `\(color.name)`, which Xcode's asset symbols both call `\(key)`: name one of them something else")
                    continue
                }
                named[key] = color.name
                // `accent` and `AccentColor` are the app's tint: the AccentColor set, never a second set by its side.
                if key == "accent" { accent = color; continue }
                palette.append(color)
            } catch { reasons.append("\(error)") }
        }
        // PIN: THE BRAND'S COLOUR IS THE TINT. With no line named `accent`, the first palette line is the app's
        // AccentColor exactly as given (it stays a set of its own too): a person who names one brand colour means it.
        // Not over an accent the catalog already has, nor from a kit's namespaced colour (`colors/background`):
        // a later call adding a kit's colours made the near-white page colour the tint (Hearth, 2026-11-01).
        let manager = FileManager.default
        let hasAccent = manager.fileExists(atPath: catalog.appendingPathComponent("AccentColor.colorset").path)
        let madeBefore = manager.fileExists(atPath: catalog.appendingPathComponent("AppIcon.appiconset").path)
        if accent == nil, !hasAccent, let first = palette.first(where: { !$0.name.contains("/") }) {
            accent = first
            notes.append("AccentColor is \(first.name), the first palette line; name a line `accent` to choose another")
        }
        var symbols: [SymbolSpec] = []
        named = [:]
        for line in (input.symbols ?? []).filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            do {
                let symbol = try SymbolLine.parse(line)
                let key = symbolKey(symbol.name, color: false)
                if drawn.contains(key) { reasons.append("symbol `\(symbol.name)` takes the name of an image the agent draws: name the symbol something else"); continue }
                if let other = named[key] {
                    reasons.append(other == symbol.name ? "symbols names `\(symbol.name)` twice"
                                   : "symbols names `\(other)` and `\(symbol.name)`, which Xcode's asset symbols both call `\(key)`: name one of them something else")
                    continue
                }
                named[key] = symbol.name
                symbols.append(symbol)
            } catch { reasons.append("\(error)") }
        }
        var data: [(spec: DataSpec, file: URL)] = []
        var seen: Set<String> = []
        for line in (input.data ?? []).filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            do {
                let spec = try DataLine.parse(line)
                if !seen.insert(spec.name.lowercased()).inserted { reasons.append("data names `\(spec.name)` twice"); continue }
                let file = files.resolve(spec.path)
                var folder: ObjCBool = false
                guard FileManager.default.fileExists(atPath: file.path, isDirectory: &folder), !folder.boolValue else {
                    reasons.append("data `\(spec.name)`: there is no file at `\(spec.path)`"); continue
                }
                data.append((spec, file))
            } catch { reasons.append("\(error)") }
        }

        // What: the sets asked for, or every kind the call gives what it needs.
        var sets: [AssetsSet]
        if let asked = input.sets {
            sets = unique(asked)
            if sets.isEmpty { reasons.append("`sets` names none: leave it out for the icon, colours, logos, launch logo, placeholders and empty states") }
            func given(_ lines: [String]?) -> Bool { (lines ?? []).contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty } }
            if sets.contains(.colors) && !given(input.palette) { reasons.append("`sets` asks for colors and `palette` gives no lines: add `name: #light/#dark` lines") }
            if sets.contains(.symbols) && !given(input.symbols) { reasons.append("`sets` asks for symbols and `symbols` gives no lines: add `name: path data in a 0…100 box`") }
            if sets.contains(.data) && !given(input.data) { reasons.append("`sets` asks for data and `data` gives no lines: add `name: path/to/file`") }
            if !symbols.isEmpty && !sets.contains(.symbols) { notes.append("the symbols lines were left out: `sets` does not ask for symbols") }
            if !data.isEmpty && !sets.contains(.data) { notes.append("the data lines were left out: `sets` does not ask for data") }
        } else if madeBefore, input.mark == nil, input.letters == nil, input.shape == nil, input.image == nil,
                  input.background == nil, input.foreground == nil, input.font == nil {
            // A catalog that has its icon, asked for more: only what the lines give, so a palette never redraws the brand.
            sets = (accent == nil ? [] : [.accent]) + (palette.isEmpty ? [] : [.colors]) + (symbols.isEmpty ? [] : [.symbols]) + (data.isEmpty ? [] : [.data])
            if sets.isEmpty { reasons.append("the catalog already has its icon and this call gives nothing new: add palette, symbols or data lines, or name the mark to draw it again") }
            else { notes.append("the icon, logos, launch logo and placeholders were kept: name the mark, its letters, shape, image, background or font to draw them again") }
        } else {
            sets = [.icon, .accent] + (palette.isEmpty ? [] : [.colors]) + [.logos, .launch, .placeholders, .empty]
                + (symbols.isEmpty ? [] : [.symbols]) + (data.isEmpty ? [] : [.data])
        }

        // Who: the app's name, its faces, its colours and its mark.
        let name = (input.name ?? "").trimmingCharacters(in: .whitespaces).isEmpty ? projectName(files.root) : input.name!.trimmingCharacters(in: .whitespaces)
        var fonts = FontChoice(monogram: "AvenirNext-Bold", wordmark: "AvenirNext-DemiBold")
        var fontFound = true
        do { fonts = try FontChoice.resolve(input.font) } catch { reasons.append("\(error)"); fontFound = false }

        var background: [SRGBColor] = []
        for text in input.background ?? [] {
            if let color = SRGBColor(hex: text) { background.append(color) } else { reasons.append("background `\(text)` is not a hex colour like #3B5BDB") }
        }
        if (input.background ?? []).count > 3 { reasons.append("background gives \(input.background!.count) colours: give one (solid) or two or three (a gradient, top to bottom)") }
        var foreground: SRGBColor?
        if let text = input.foreground {
            if let color = SRGBColor(hex: text) { foreground = color } else { reasons.append("foreground `\(text)` is not a hex colour like #FFFFFF") }
        }
        var kind = input.mark ?? (input.image != nil ? .image : input.shape != nil ? .shape : .monogram)
        var glyph: AssetsShape?
        if let shape = kind.namedShape { glyph = shape; kind = .shape }
        var picture: Picture?
        var pictureRefusal: String?
        if kind == .image, let path = input.image?.trimmingCharacters(in: .whitespaces), !path.isEmpty {
            do { picture = try Picture.load(files.resolve(path)) } catch { pictureRefusal = "\(error)" }
        }
        if (input.background ?? []).isEmpty {
            if let picture, picture.isFullBleed {
                // A whole-icon picture is the brand's ground: its own colours light the dark looks and illustrations.
                background = picture.halves()
            } else if let accent {
                let tone = accent.light.oklch
                background = [tone.with(l: tone.l + 0.05, h: tone.h - 5).rgb, tone.with(l: tone.l - 0.07, h: tone.h + 7).rgb]
            } else {
                background = BrandDefaults.gradient(for: name)
            }
        }
        // PIN: A MARK THAT DOES NOT SHOW IS NOT A MARK. A given colour under 3:1 against the middle of its background
        // (the floor for a graphic, WCAG 1.4.11) is set aside for white or ink, whichever reads, and the answer says so.
        if let given = foreground {
            let ground = BrandTones.middle(of: Array(background.prefix(3)))
            let ratio = given.contrast(with: ground)
            if ratio < 3 {
                notes.append("the mark's colour \(input.foreground ?? "") shows at only \(String(format: "%.1f", ratio)):1 on its background, under the 3:1 a mark needs, so the mark is white or ink, whichever reads")
                foreground = nil
            }
        }
        let tones = BrandTones.derive(background: Array(background.prefix(3)), foreground: foreground, accent: accent.map { ($0.light, $0.dark) })

        var mark = BrandMark.monogram("A")
        switch kind {
        case .monogram:
            let letters = (input.letters ?? "").trimmingCharacters(in: .whitespaces).isEmpty ? initials(name) : input.letters!.trimmingCharacters(in: .whitespaces)
            if letters.count > 3 { reasons.append("letters `\(letters)` is \(letters.count) characters: a monogram is one to three; the name goes in the wordmark") }
            else if fontFound {
                do { _ = try TextOutline.path(letters, font: fonts.monogram, size: 64) } catch { reasons.append("\(error)") }
            }
            mark = .monogram(letters)
        case .shape:
            if let shape = glyph ?? input.shape { mark = .shape(shape) }
            else { reasons.append("mark is shape and `shape` names no glyph: one of \(AssetsShape.allCases.map(\.rawValue).joined(separator: ", "))") }
        case .image:
            if let picture { mark = .image(picture) }
            else if let pictureRefusal { reasons.append(pictureRefusal) }
            else {
                reasons.append("mark is image and `image` names no file: give a PNG, JPEG, PDF or SVG in the project")
            }
        case .ring, .knot, .wave, .spark, .stack, .leaf, .bubble, .grid:
            break   // a shape's own name was read as `shape` above
        }
        let wordmark = (input.wordmark ?? "").trimmingCharacters(in: .whitespaces).isEmpty ? name : input.wordmark!.trimmingCharacters(in: .whitespaces)
        if sets.contains(.logos), fontFound {
            do { _ = try TextOutline.path(wordmark, font: fonts.wordmark, size: 64) } catch { reasons.append("\(error)") }
        }

        guard reasons.isEmpty else { throw AssetsError.refused(reasons) }
        let brand = Brand(name: name, wordmark: wordmark, mark: mark, fonts: fonts, tones: tones)
        return AssetsPlan(files: files, catalog: catalog, sets: sets, platforms: platforms, brand: brand, contrast: input.contrast ?? false,
                          accent: accent, palette: palette, symbols: symbols, data: data, notes: notes)
    }

    /// The first letter of a one-word name, the first letters of the first two words of a longer one.
    static func initials(_ name: String) -> String {
        let words = name.split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "_" }).map { $0.filter { $0.isLetter || $0.isNumber } }.filter { !$0.isEmpty }
        let letters = words.prefix(words.count > 1 ? 2 : 1).compactMap(\.first).map { String($0).uppercased() }.joined()
        return letters.isEmpty ? "A" : letters
    }

    /// The app's name when the call gives none: the project's Xcode project, else its folder's name.
    static func projectName(_ root: URL) -> String {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: root.path)) ?? []
        if let project = names.sorted().first(where: { $0.hasSuffix(".xcodeproj") }) { return String(project.dropLast(10)) }
        let folder = root.lastPathComponent
        return folder.first?.isUppercase == true ? folder : "App"
    }

    private static func unique<T: Hashable>(_ items: [T]) -> [T] {
        var seen: Set<T> = []
        return items.filter { seen.insert($0).inserted }
    }
}
