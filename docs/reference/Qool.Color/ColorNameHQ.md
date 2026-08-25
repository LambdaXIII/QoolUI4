# ColorNameHQ

The QML-facing color name singleton — registered in QML as **`ColorHQ`**
(C++ class `ColorNameHQ`, `QML_NAMED_ELEMENT(ColorHQ)`): aggregates all
color name provider plugins and offers bidirectional name ↔ color lookup.

`ColorHQ` is a QML singleton with **one independent instance per
`QQmlEngine`** (created by `create()`, parented to the engine) — in
multi-engine scenarios (the QML test framework creates one engine per
file; multi-window/multi-view hosts) each engine uses its own object and
they do not share instances. The color name data itself is shared at the
app level: the underlying `ColorNameDB` (a process-level C++ singleton)
owns the provider table and the name cache, installs every
`ColorNameProvider` plugin automatically through `PluginLoader` at
construction, and sorts them into the provider table by the `priority`
field of the plugin's json metadata. When no plugin is installed a
warning is emitted and only the default-value paths of `color()` /
`colorName()` remain usable.

This component also carries the `ColorLiterals` shared helpers
(`QML_EXTENDED(ColorLiterals)`), so every `ColorLiterals` static method
— channel names/tags/colors, the channel-value format/parse/clamp pair,
`visualBrightness`, `keepItBright` / `keepItDark`, and the `Channels`
enum — is callable directly on the `ColorHQ` singleton (this is the
canonical access path; `ColorAssistant` does not extend `ColorLiterals`).

### Plugin priority

- `colorNames()` — the union of all providers' names (filterable by
  `category`, sorted before returning).
- `color()` / `colorName()` — providers are consulted in ascending
  `priority` order and the first one able to answer (its `std::optional`
  has a value) wins — a "supplement" arbitration (low-priority providers
  offer the base names, high-priority ones only supplement queries they
  do not cover), **not** high-priority override. When no provider answers,
  `color()` returns the caller-supplied `def` (default white) and
  `colorName()` returns the `QColor::name()` `#RRGGBB` / `#AARRGGBB` text.
- `categories()` — deduplicated; the high-priority providers' categories
  come first.

Priority is defined **only** in the plugin json metadata `priority`
field (`PluginLoader` reads it from the metadata); the
`ColorNameProvider` interface deliberately exposes **no** `priority()`
method — implementers cannot bypass the loader's metadata arbitration
(editing the json adjusts the override order without code changes or
recompilation). This is a v4 contract; do not add `priority()` back to
the interface.

### Name cache (`isProvidedColorName`)

At plugin install time each provider's names are merged into the internal
`m_nameCache`; `isProvidedColorName()` decides against that cache in O(1)
without iterating providers. Names added after installation therefore do
not appear in `isProvidedColorName()` (plugins declare static color
tables, so this scenario does not arise in normal operation).

## Properties

This type defines no properties (the `Channels` enum is accessed as
`ColorHQ.Channels`, and the `channels` list constant as
`ColorHQ.channels`).

## Signals

This type defines no signals.

## Methods

- `list<string> colorNames(string category)`
  Returns the union of all providers' names, optionally filtered by
  `category`, sorted.

- `color color(string name, color def)`
  Resolves a name (or hex string) to a color; the first provider in
  ascending priority order that can answer wins. If none can, returns
  `def` (default `Qt::white`).

- `list<string> categories()`
  Returns the deduplicated union of all providers' categories,
  high-priority providers first.

- `bool isProvidedColorName(string name)`
  Returns whether the name is in the installed cache (O(1), no provider
  iteration).

- `bool isValidColorName(string name)`
  Returns `isProvidedColorName(name)` **or** `QColor::isValidColorName`
  — accepts both plugin-provided names and any valid QColor color-name /
  hex literal.

- `string colorName(color)`
  Returns the nearest color name for the color; the first provider in
  ascending priority order that can answer wins. If none can, returns the
  `#RRGGBB` / `#AARRGGBB` text of `QColor::name()`.

### ColorLiterals helpers (via `QML_EXTENDED`)

- `string channelName(int)` / `string channelNameF(int)` /
  `string channelTag(int)` / `string channelTagShort(int)` /
  `color channelColor(int)` — channel metadata (property name, F-variant
  name, display tag, short tag, identity color).
- `string formatChannelNumberFloat(real)` — formats a normalized channel
  value, deliberately exactly four outputs: `"0"`, `"1"`, `".xxx"`
  (three decimal digits without a leading zero, e.g. `.350`), `"NaN"`.
  Values rounding to 1000 (≥ 0.9995) collapse to `"1"`.
- `real parseChannelNumberFloat(string)` — the reverse: cleans the input
  (keeps digits and the *first* decimal point only), prepends a decimal
  point when none is present (integers read as pure decimals, so `"350"`
  means `.350` = 0.35), then parses; failure yields `NaN`. `"1"` parses
  back as `.1` = 0.1 (leading-dot convention).
- `real clampChannelRange(real)` — clamps to `[0, 1]`.
- `real visualBrightness(color)` — perceptual brightness
  (`0.299/0.587/0.114` weighted).
- `color keepItDark(color)` / `color keepItBright(color)` —
  darken/lighten a color for contrast application.

## Usage Example

```qml
import QtQuick
import Qool.Color

// Singleton access — no instantiation needed. The QML name is ColorHQ.
Text {
    text: ColorHQ.colorName("#ff0000")      // e.g. "red"
}

// Parse user input with a fallback.
ColorHQ.color("navy", "#000000")

// Iterate the plugin-declared categories.
ListView {
    model: ColorHQ.categories()
    delegate: Text { text: modelData }
}

// Channel constants come off the same singleton.
ColorChannelSlider {
    channel: ColorHQ.HSVHue
}
```
