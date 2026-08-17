# PaPaWall

A decorative wall that randomly rotates large characters on a colored
background.

`PaPaWall` fills its area with a background color and displays one large word
centered on it, applying a random offset, a random scale and a random
rotation of ±45° each time `refresh()` is called. `highColor`/`lowColor`
control the background and text colors, `words` provides the word pool
(default `Style.papaWords`), `font` and `text` control the text appearance
and current content, and `textSizeMode` selects the font-size strategy.

## Properties

- `highColor : color` (default `Style.highlight`)
  The background color.

- `lowColor : color` (default `Style.highlightedText`)
  The text color.

- `words : list<string>` (default `Style.papaWords`)
  The word pool; `refresh()` picks a random entry.

- `font : font`
  The displayed text's font. The type also sets `font.bold: true` and
  `font.pixelSize: round(min(width, height) / 2)` by default.

- `text : string` (alias to the internal `Text.text`)
  The currently displayed word.

- `textSizeMode : int` (default `PaPaWall.DependsOnFontSize`)
  The font-size strategy. The type declares the `TextSizeMode` enum:

  - `PaPaWall.LargerTextSize` — scale by the larger edge (max of width and
    height);
  - `PaPaWall.SmallerTextSize` — scale by the smaller edge (min of width and
    height);
  - `PaPaWall.DependsOnFontSize` (default) — 1–2× random scale, respecting
    the font settings and unrelated to the control's edges.

  (The old code referenced nonexistent `RespectFontSize`/`LargetTextSize`
  enum members, which caused a runtime `ReferenceError` and disabled the
  whole feature; the valid members are the three above.)

## Signals

This type defines no additional signals (it derives from `Item`).

## Methods

- `refresh()`
  Picks a random word from `words` (a no-op when the picked word is empty),
  applies a random vertical/horizontal offset (±37.5% of the height/width),
  a random scale factor (per `textSizeMode`) and a random rotation in
  [-45°, +45°], then updates the display.

## Usage Example

```qml
import QtQuick
import Qool.Controls.Components

// Decorative background wall that changes every few seconds.
PaPaWall {
    anchors.fill: parent
    words: ["Qool", "UI", "4"]

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: parent.refresh()
    }
}

// Custom colors and a fixed displayed word.
PaPaWall {
    width: 300
    height: 200
    highColor: Style.active.dark
    lowColor: Style.active.highlight
    text: "Qool"
}
```
