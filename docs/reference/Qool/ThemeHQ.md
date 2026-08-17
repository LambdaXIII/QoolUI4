# ThemeHQ

The theme QML-face singleton of the `Qool` module: theme lookup, installation
and foreground contrast-color recommendation.

`ThemeHQ` is a QML singleton, instantiated once **per `QQmlEngine`** (created
via `create()`, parented to the engine) — in multi-engine scenarios (QML test
framework builds a separate engine per file; multi-window/multi-view hosts)
each engine uses its own `ThemeHQ` object and they do not share objects. The
theme data itself is **app-level shared**: the underlying `ThemeDB`
(process-wide C++ global singleton) holds all themes and plugins, so any
engine's `ThemeHQ` queries the same data; `installTheme()` results are
immediately visible to all engines (`themeInstalled` is re-emitted within the
engine where the install happened).

Theme data source and injection: the default theme is derived from the system
palette (`SystemTheme`); theme plugins are auto-installed via `PluginLoader`.
A host that must decide a theme before startup can operate on `ThemeDB` from
the C++ side to preset data (this class is the QML face only).

## Behavior

- `theme(name)` — look up a theme by name (value type `Theme`); unknown names
  fall back to the first installed theme.
- `anyValue(group/key)` — cross-theme scan: the value of the first theme
  containing the key wins; returns the default value when none does.
- `installTheme(theme)` — install a theme (write face); duplicate or empty
  names are rejected without emitting `themeInstalled`. Installation also
  emits `rowsInserted` through the underlying model (a `ThemeHQModel` view
  updates live).
- `recommendForeground(bgColor, light, dark)` / `visualBrightness` — static
  utilities: black/white contrast foreground recommendation for a background
  (brightness thresholds 0.4/0.6) and perceived brightness
  (0.299/0.587/0.114 weighted).

## Properties

- `themes : stringList` (read-only)
  The list of installed theme names.

- `count : int` (read-only)
  The number of installed themes.

> **Note:** `themes`/`count` read the shared DB but carry no change
> notification — the DB's `themesChanged`/`countChanged` are never emitted
> (installation only emits `themeInstalled`). QML bindings on
> `themes`/`count` do not refresh on install; use `ThemeHQModel` for a live
> list.

## Signals

- `themeInstalled(string name)`
  Re-emitted (within this engine) when a theme is installed through the
  shared `ThemeDB`. Emitted from any engine's `installTheme()`.

- `themesChanged()`
  Declared for the `themes` property; never actually emitted (see the note
  above).

- `countChanged()`
  Declared for the `count` property; never actually emitted (see the note
  above).

## Methods

- `theme(name : string) : Theme`
  Returns the theme with the given name; unknown names fall back to the
  first installed theme.

- `installTheme(theme : Theme)`
  Installs the given theme. Duplicate or empty names are rejected without
  emitting `themeInstalled`.

- `anyValue(group : int, key : string, defvalue : variant = {}) : variant`
  Cross-theme scan restricted to the given `group`: returns the value of the
  first theme containing `key` in that group, else `defvalue`.

- `anyValue(key : string, defvalue : variant = {}) : variant`
  Cross-theme scan across all groups: returns the value of the first theme
  containing `key`, else `defvalue`.

- `visualBrightness(color : color) : real`
  Static: returns the perceived brightness of `color`
  (0.299/0.587/0.114 weighted).

- `recommendForeground(bgColor : color, light : color = "white",
  dark : color = "black") : color`
  Static: returns a black/white contrast foreground for `bgColor`. Uses
  brightness thresholds 0.4/0.6 against the given light/dark candidates.

## Usage Example

```qml
import QtQuick
import Qool

Text {
    // Pick a readable foreground for the current background.
    color: ThemeHQ.recommendForeground(Style.base, Style.light, Style.dark)
    text: "Hello"
}

// Install a theme at runtime (affects every engine's data).
// ThemeHQ.installTheme(myTheme)
```
