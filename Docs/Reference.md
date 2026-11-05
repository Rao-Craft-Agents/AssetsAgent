# AssetsAgent reference

How the `assets` agent is found, what a call takes and answers, the lines it reads, the sets it makes, how they are
drawn, and how to test it. What it is for is in the [README](../README.md); the agent standard it follows is Granite's
[granite-agent/1](https://github.com/riteshpakala/Granite/blob/main/Schema/GraniteAgent.md).

## How an app finds it

AssetsAgent is a `GraniteAgentPackage`, and it carries a record in its binary:

```swift
@used @section("__DATA_CONST,__granite")
let assetsRecord: GraniteRoster.Record = { GraniteRoster.record(AssetsAgent.self) }
```

In [Craft](https://github.com/riteshpakala/Craft), install it from the Agent Store or with
`craft agents add https://github.com/Rao-Craft-Agents/AssetsAgent.git`, then say `$assets` in a request:

```
$assets brand the recipe app Simmer: its S in Didot on a warm orange gradient, a cream paper colour
and a herb green, and a whisk symbol
```

The model writes the call; it shows on Craft's agent map as `assets-1`, and the catalog it names is built with the turn.

## What a call takes and answers

| Field | | |
|---|---|---|
| `into` | optional | the asset catalog, relative to the project; `Shared/Assets.xcassets` when left out |
| `name` | optional | the app's name: the monogram's initials and the wordmark; the Xcode project's name when left out |
| `mark` | optional | `monogram` (the default), `shape` or `image` |
| `letters` | optional | the monogram's one to three letters; the name's initials when left out |
| `shape` | optional | `ring`, `knot`, `wave`, `spark`, `stack`, `leaf`, `bubble` or `grid` |
| `image` | optional | a PNG, JPEG, PDF or SVG in the project; a square opaque PNG is the whole icon |
| `background` | optional | the icon's ground as hex: one colour (solid) or two or three (a gradient); picked from the name when left out |
| `foreground` | optional | the mark's colour; white or ink, by contrast, when left out |
| `palette` | optional | one colour set a line (below) |
| `contrast` | optional | whether every colour set also gets high-contrast colours |
| `font` | optional | a bundled macOS family or face: Avenir Next (the default), Futura, Georgia, Didot, Gill Sans, Menlo… |
| `wordmark` | optional | the wordmark's text; the name when left out |
| `sets` | optional | `icon`, `accent`, `colors`, `logos`, `launch`, `placeholders`, `empty`, `symbols`, `data`; all but symbols and data when left out |
| `symbols` | optional | one custom symbol a line (below) |
| `data` | optional | one data set a line: `pantry: Resources/pantry.json` |
| `platforms` | optional | `ios`, `macos`, `watchos`, `visionos`; iOS and macOS when left out |
| `directory` | the host's | the folder the host works in; a host fills it and does not show it to a model |

The answer is an `AssetsResult`: every file written (`path`, the largest icon; `paths`, all of them, absolute), the
catalog, the sets by the names code uses, and a sentence for anything the project still needs (an app target that names
no icon, a launch screen that does not name the launch logo).

## The lines

```
palette:  paper: #FFF8F0/#1C1714          light, then dark
          ink: #1D1B19                    the same in both
          danger: #D93A2B/#FF6B5E/#A3180D/#FFA39A   light, dark, then each in high contrast
          accent: #E8590C/#FF8A4C         the app's tint: the AccentColor set
          LaunchBackground: #FFF8F0/#1C1714   the launch screen's colour
symbols:  whisk: M30 90 L50 40 L70 90 M50 40 L50 10
          pin.fill: M50 94 C50 94 18 62 18 40 A32 32 0 0 1 82 40 C82 62 50 94 50 94 Z M50 28 A12 12 0 1 0 50.01 28 Z
data:     pantry: Resources/pantry.json
```

- A symbol is SVG path data in a 0…100 box, y down: every command, absolute and relative, arcs included. The path is
  the symbol's centre line, stroked at Ultralight, Regular and Black; a name ending `.fill` (or `fill` before the
  colon) fills it, holes and all.
- Two names Xcode's asset symbols would make the same (`paper` and `paperColor`, `pin.fill` and `pinFill`) are refused,
  so the app's build never warns; a palette line named `accent` is the AccentColor itself.
- Every line, value and font that cannot be honoured is refused with its reason, all at once, and nothing is written.

## What it makes

| Set | What |
|---|---|
| `AppIcon` | iOS: one 1024 square in its any, dark and tinted looks. macOS: the rounded square on Apple's grid (824 of 1024, continuous corners, shadow) at all ten sizes, each drawn at its size, 16 and 32 pixels from a simpler cut. watchOS: one 1024 square (its own `WatchAppIcon` beside Mac sizes). visionOS: `AppIcon.solidimagestack`, front, middle and back layers |
| `AccentColor` and a set a palette line | sRGB, light and dark, high contrast when asked |
| `Logo`, `LogoMark`, `Wordmark`, `Lockup` | vector PDFs: the badge, the mark alone as a template, the name outlined in the brand's face, badge and name; light and dark |
| `LaunchLogo` | the icon's rounded square, light and dark |
| `Placeholder/Avatar`, `Placeholder/Avatar1…4` | a neutral avatar, light and dark, and four sample avatars for previews and seed data |
| `Empty/Inbox`, `Empty/Search`, `Empty/Offline`, `Empty/Error` | empty-state illustrations, light and dark |
| `<name>.symbolset` | an SF Symbols template (v3) a symbol line: `Image("whisk")` at every weight and scale |
| `<name>.dataset` | the file, with its uniform type |

Code reads them as `Image("Logo")`, `Image(.logo)`, `Image("Placeholder/Avatar")`, `Color("paper")`, `Color.accentColor`,
`Image("whisk")`, `NSDataAsset(name: "pantry")`.

## How the assets are made

| Step | What |
|---|---|
| Read | every field and line checked; a call that cannot be honoured names every reason |
| Colour | the brand's tones in OKLCH from what the call gives: the dark looks keep the brand's hue, the accent is moved until it reads on white and on black |
| Draw | the mark (letters outlined from the font, a glyph built from circles and strokes, or the picture) on the brand's ground; PNGs for icons, vector PDFs for everything else |
| Write | every set staged with the `Contents.json` Xcode 27 writes, byte for byte |
| Check | the staged catalog compiled by actool for every platform asked for; an error writes nothing |
| Land | each set swapped in whole for the one of its name; every other set in the catalog is left alone |

Apple's SF Pro, SF Symbols and New York never appear in an icon or a logo: their licence keeps them out. A letter the
chosen face lacks is refused rather than set by macOS in another font.

## Testing

```
swift test                    # the record, the schema, the lines, every Contents.json, the pixels, actool for iOS,
                              # macOS, watchOS and visionOS, what the compiled catalog loads, running again
ASSETS_BUILD=1 swift test     # the catalog in a two-platform app: xcodebuild for macOS and the iOS Simulator with no
                              # asset warning, and the Mac app run to report what it finds in its own bundle
```
