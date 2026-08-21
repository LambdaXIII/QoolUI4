# ColorNameHQ

The QML-facing color name singleton: aggregates all color name provider
plugins and offers bidirectional name ↔ color lookup.

`ColorNameHQ` is a QML singleton with **one independent instance per
`QQmlEngine`** (created by `create()`, parented to the engine) — in
multi-engine scenarios (the QML test framework creates one engine per
file; multi-window/multi-view hosts) each engine uses its own
`ColorNameHQ` object and they do not share objects. The color name data
itself is shared at the app level: the underlying `ColorNameDB` (a
process-level C++ singleton) owns the provider table and the name cache,
installs every `ColorNameProvider` plugin automatically through
`PluginLoader` at construction, and sorts them into the provider table by
the `priority` field of the plugin's json metadata. When no plugin is
installed a warning is emitted and only the default-value paths of
`color()`/`name()` remain usable.

### Plugin priority

- `names()` — the union of all providers' names (filterable by
  `category`, sorted before returning).
- `color()` / `name()` — providers are consulted in ascending `priority`
  order and the first one able to answer (its `std::optional` has a
  value) wins — a "supplement" arbitration (low-priority providers offer
  the base names, high-priority ones only supplement queries they do not
  cover), **not** high-priority override. When no provider answers,
  `color()` returns the caller-supplied `def` (default white) and
  `name()` returns the `QColor::name()` `#RRGGBB` / `#AARRGGBB` text.
- `categories()` — deduplicated; the high-priority providers' categories
  come first.

Priority is defined **only** in the plugin json metadata `priority`
field (`PluginLoader` reads it from the metadata); the
`ColorNameProvider` interface deliberately exposes **no** `priority()`
method — implementers cannot bypass the loader's metadata arbitration
(editing the json adjusts the override order without code changes or
recompilation). This is a v4 contract; do not add `priority()` back to
the interface.

### Name cache (`hasColor`)

At plugin install time each provider's names are merged into the internal
`m_nameCache`; `hasColor()` decides against that cache in O(1) without
iterating providers. Names added after installation therefore do not
appear in `hasColor()` (plugins declare static color tables, so this
scenario does not arise in normal operation).

## Properties

This type defines no properties.

## Signals

This type defines no signals.

## Methods

- `list<string> names(string category)`
  Returns the union of all providers' names, optionally filtered by
  `category`, sorted.

- `color color(string name, color def)`
  Resolves a name (or hex string) to a color; the first provider in
  ascending priority order that can answer wins. If none can, returns
  `def` (default `Qt::white`).

- `list<string> categories()`
  Returns the deduplicated union of all providers' categories,
  high-priority providers first.

- `bool hasColor(string name)`
  Returns whether the name is in the installed cache (O(1), no provider
  iteration).

- `string name(color)`
  Returns the nearest color name for the color; the first provider in
  ascending priority order that can answer wins. If none can, returns the
  `#RRGGBB` / `#AARRGGBB` text of `QColor::name()`.

- `string formatChannelNumberFloat(real num)`
  Formats a normalized channel value — deliberately exactly four outputs:
  `"0"`, `"1"`, `".xxx"` (three decimal digits without a leading zero,
  e.g. `.350`), `"NaN"`. Values rounding to 1000 (≥ 0.9995) collapse to
  `"1"`.

- `real parseChannelNumberFloat(string input)`
  Parses a normalized channel value (the reverse of
  `formatChannelNumberFloat`): cleans the input (keeps digits and the
  *first* decimal point only), prepends a decimal point when none is
  present — integers are read as pure decimals, so `"350"` means `.350` =
  0.35 — then parses the number; failure (empty / no digits) yields `NaN`.
  Note `"1"` parses back as `.1` = 0.1 (a consequence of the
  leading-dot convention).

## Usage Example

```qml
import QtQuick
import Qool.Color

// Singleton access — no instantiation needed.
Text {
    text: ColorNameHQ.name("#ff0000")      // e.g. "red"
}

// Parse user input with a fallback.
ColorNameHQ.color("navy", "#000000")

// Iterate the plugin-declared categories.
ListView {
    model: ColorNameHQ.categories()
    delegate: Text { text: modelData }
}
```
