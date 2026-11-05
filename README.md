# AssetsAgent

Give an app its brand in one request. Say the app's name and, if you like, a mark, colours and a font, and `assets`
draws the app icon, the accent and palette colours, logos, placeholder avatars, empty-state pictures and custom
symbols into its asset catalog, each set written as Xcode would write it. Everything is drawn on your Mac; no model is
asked.

## What you can ask

```
$assets brand the recipe app Simmer: its S in Didot on a warm orange gradient, a cream paper colour and a herb green
$assets a leaf on a deep green for Simmer's icon, drawn for the Apple Watch and Vision Pro too
$assets use Design/simmer-mark.svg as the mark
$assets a whisk symbol and a timer symbol
```

Craft's model writes the call; it shows on Craft's agent map, and the catalog it names is built with the turn.

## What you get

- **An app icon for every platform.** iOS in its any, dark and tinted looks; the Mac's rounded square on Apple's grid
  at all ten sizes, each drawn at its size, the smallest from a simpler cut; watchOS and visionOS when asked.
- **The brand's colours.** The accent colour and a colour set for each palette colour, in light and dark, with
  high-contrast colours when asked.
- **Logos and a launch logo.** Vector PDFs of the badge, the mark alone, the name in the brand's face and the two
  together, light and dark.
- **Placeholders and empty states.** A neutral avatar and four sample avatars for previews and seed data, and pictures
  for an empty inbox, an empty search, offline and an error.
- **Custom symbols and data.** An SF Symbols template from SVG path data, at every weight and scale, and project files
  kept as data sets.
- **Names your code already reads.** `Image("Logo")`, `Color("paper")`, `Color.accentColor`, `Image("whisk")`,
  `NSDataAsset(name: "pantry")`.

## How it works

- It works the brand's tones out from what you give it, so the dark looks keep the brand's hue and the accent reads on
  white and on black.
- Every line, value and font is checked first. A request it cannot honour is refused with every reason at once, and
  nothing is written.
- The catalog is compiled by Xcode's asset catalog compiler for every platform asked for before it lands; an error
  writes nothing. Running it again swaps in only the sets it makes and leaves every other set alone.
- It does not edit the Xcode project. The answer says what the project still needs for the assets to show, such as an
  app target that names no icon.

## Works well with

`granite` is where an app starts, and the other Rao Craft Agents fill it in. `assets` draws the brand every other
layer shows: the icon on the Home Screen and in the Dock, the tint, the logo on an about page, the avatar a feed shows
for someone with no picture, the picture an empty list shows. `design` can read the colour sets it writes by name.

## Get it

In Craft, install Assets from the Agent Store, or run
`craft agents add https://github.com/Rao-Craft-Agents/AssetsAgent.git`, then say `$assets` in a request.

## Requirements

- A Mac on macOS 14 or later, with Xcode: its asset catalog compiler checks each catalog before it lands.
- It draws for iOS and macOS, and for watchOS and visionOS when asked.
- Fonts are the faces bundled with macOS, Avenir Next by default. Apple's SF Pro, SF Symbols and New York never appear
  in an icon or a logo: their licence keeps them out.
- MIT licensed.

## For developers

What a call takes and answers, the lines it reads, the sets it makes and how each is drawn are in the
[reference](Docs/Reference.md). The agent standard it follows is Granite's
[granite-agent/1](https://github.com/riteshpakala/Granite/blob/main/Schema/GraniteAgent.md), and how it is tested is
[TESTING.md](TESTING.md).
